# OpenRouter verification and drafting

Verily can judge media proof and draft actions through OpenRouter, with a
person as the fail-closed outcome. Both are off until a backend-only
`VERILY_OPENROUTER_API_KEY` is configured: without it, media proof goes to
manual review and drafting returns `ActionDraftingUnavailableException` with
friendly copy while templates keep working.

## Policies

Creators choose a policy per media requirement:

| Policy         | Models                                                                                   | Decides when                                                    |
| -------------- | ---------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `singleModel`  | The primary model (Gemini 2.5 Flash-Lite by default)                                     | One decisive vote meets the rule's confidence                   |
| `modelCouncil` | Three models in parallel (default Gemini 2.5 Flash-Lite, Gemma 4 26B A4B, GLM-5.3-Flash) | Two models return the same decisive verdict above the threshold |

Uncertain, malformed, failed, out-of-budget, or low-confidence votes abstain.
Without a quorum the proof goes to a person. One vote that reports prompt
injection forces review even if the others accept.

## Model registry

Arbitrary model ids are refused at startup.

| Model                                   | Image | Video             | Audio | Hears speech | Response schema                |
| --------------------------------------- | ----- | ----------------- | ----- | ------------ | ------------------------------ |
| `google/gemini-2.5-flash-lite`          | Yes   | Yes               | Yes   | Yes          | Strict JSON schema             |
| `google/gemini-2.5-flash`               | Yes   | Yes               | Yes   | Yes          | Strict JSON schema             |
| `google/gemma-4-26b-a4b-it`             | Yes   | Yes (about 1 fps) | No    | No           | Strict JSON schema             |
| `z-ai/glm-5.3-flash`                    | Yes   | Yes               | No    | No           | JSON object, validated locally |
| `deepseek/deepseek-v4-flash-vision-exp` | Yes   | No                | No    | No           | JSON object, validated locally |

Every council member must accept video. Audio is sent inline as base64
(`input_audio`, m4a or webm) because OpenRouter does not take audio URLs, and
it is downloaded once only when a configured model can use it. Photos never
carry a duration.

### Audio and the spoken challenge

A model that cannot hear the media cannot vote on the challenge word; it
abstains. Consequences, by design:

- A `singleModel` audio or video proof with a word is decided by the primary
  model, which must hear it.
- The default council has one hearing member, so a council proof with a
  spoken word, and any council audio proof, goes to a person. To let a council
  decide spoken proof automatically, configure at least two hearing members,
  for example `google/gemini-2.5-flash-lite,google/gemini-2.5-flash,google/gemma-4-26b-a4b-it`.
- `heard` from the quorum with no `notHeard` accepts; `notHeard` from the
  quorum with no `heard` rejects (`spoken_challenge_not_heard`); anything else
  goes to a person. The word never changes the action verdict.

## Prompt-injection boundary

- Requests carry exactly one server-owned system message and one user/data
  message, no tools, and a pinned model. Clients and creators cannot pick a
  model, role, message, schema, provider option, or media URL.
- Creator text passes `ModelInputSecurity` when authored and again before use.
  Suspicious text is rejected, never stripped and forwarded.
- The system prompt treats the requirement, the challenge word, and all media
  (speech, signs, screens, subtitles, encoded content, role labels, control
  tokens) as evidence, not instructions.
- Only a bounded vote is parsed: exactly `verdict`, `confidence`,
  `prompt_injection_detected`, and `challenge_word_heard` when the model can
  hear the word. Extra or missing fields fail the vote
  (`openrouter_unexpected_fields`), including for models without provider-side
  schema enforcement. Raw model prose is never stored or shown.
- An OpenRouter guardrail `403` becomes a stable failed vote; its body is not
  kept.
- Requests set `data_collection: deny` and require zero-data-retention
  routing unless `VERILY_OPENROUTER_REQUIRE_ZDR=false` is set explicitly.
- Each vote stores requested and resolved model ids, provider, response id,
  verdict, confidence, word verdict, latency, tokens, cost, and a stable error
  code. The decision and its votes commit in one transaction.

A model verdict is an untrusted signal. Completion, ranking, and payout
reservation stay deterministic server decisions with their own checks.

## Cost bounds

There are no credits. `InferenceCostPolicy` caps cost per model call, calls per
attempt, and micros per attempt; `InferenceReservationService` reserves each
call against the attempt under an advisory lock before it is sent. A call that
would exceed the budget is a failed vote (`verification_budget_unavailable`),
which sends the proof to a person. With no approved cost policy, every call is
refused.

## Drafting

`draftActionFromPrompt` sends the creator's idea, quoted as data, to the pinned
`google/gemini-2.5-flash` with a strict schema and ZDR. The output is validated
again with `ModelInputSecurity` and the authoring rules, and refused when it
names a reward, a venue code, an App, unknown fields, or anything that looks
like an instruction. Motion thresholds in a draft are server-owned. Each
account gets `VERILY_AI_ACTION_DRAFT_DAILY_UNITS` (default 20) per UTC day,
with at most two drafts in flight; failed work still spends its units.
`VERILY_AI_ENABLED` defaults to off in production.

## Configuration

```text
VERILY_MEDIA_VERIFIER_MODE=openrouter
VERILY_OPENROUTER_API_KEY=<backend-only secret, via Monosecret>
VERILY_OPENROUTER_URL=https://openrouter.ai/api/v1/chat/completions
VERILY_OPENROUTER_PRIMARY_MODEL=google/gemini-2.5-flash-lite
VERILY_OPENROUTER_COUNCIL_MODELS=google/gemini-2.5-flash-lite,google/gemma-4-26b-a4b-it,z-ai/glm-5.3-flash
VERILY_OPENROUTER_REQUIRE_ZDR=true
VERILY_OPENROUTER_PROMPT_INJECTION_GUARD=block
VERILY_MEDIA_VERIFIER_TIMEOUT_SECONDS=90
```

Any mode other than `manual-review` also requires the attested deployment
policy `verily.ai-deployment.production.v1`, in every run mode:
`VERILY_AI_DEPLOYMENT_ENABLED=true`, `VERILY_AI_DEPLOYMENT_POLICY_VERSION`,
`VERILY_AI_DEPLOYMENT_ID`, `VERILY_AI_GUARDRAIL_ID`,
`VERILY_AI_GUARDRAIL_POLICY_DIGEST`, `VERILY_AI_ZDR_POLICY_ID`,
`VERILY_AI_RATE_CARD_DIGEST`, `VERILY_AI_RATE_CARD_MEASURED_AT`,
`VERILY_AI_ATTESTATION_MAX_AGE_SECONDS`, the request limits
(`VERILY_AI_MAX_CONCURRENT_REQUESTS`, `VERILY_AI_MODEL_REQUESTS_PER_MINUTE`,
`VERILY_AI_HEALTH_WINDOW_MINUTES`), and the cost policy
(`VERILY_AI_COST_POLICY_VERSION`, `VERILY_AI_MODEL_MAX_COST_MICROS`,
`VERILY_AI_MAX_CALLS_PER_ATTEMPT`, `VERILY_AI_MAX_MICROS_PER_ATTEMPT`).
Without `VERILY_AI_DEPLOYMENT_ENABLED=true` the cost policy is disabled and every
model call is refused. Partial or stale configuration stops startup.

Before setting `VERILY_OPENROUTER_PROMPT_INJECTION_GUARD=block`, assign the key
to an OpenRouter guardrail whose prompt-injection action is **Block**, pin the
allowed models, and require ZDR for every provider group. Do not allowlist
phrases from creator or media content. The variable is a deployment assertion
that makes partial setups fail closed; it cannot prove the remote assignment.

## Rollout gate

Before automatic acceptance, per action family, media kind, and policy:

- false-accept, false-reject, abstention, and human-overturn rates;
- end-to-end latency (p50, p90, p99) including media fetch;
- actual cost per verification from stored votes;
- edited, replayed, sped-up, occluded, generated, wrong-action, and
  prompt-injection cases, and wrong or missing challenge words;
- results by camera, lighting, device, and relevant cohorts;
- council disagreement pairs, so correlated failures stay visible.

Start with decisions forced to review, compare votes with human labels, set
per-family thresholds, and keep `VERILY_MEDIA_VERIFIER_MODE=manual-review` as
the immediate kill switch.
