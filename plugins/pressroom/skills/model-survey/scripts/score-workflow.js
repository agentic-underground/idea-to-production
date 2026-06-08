// score-workflow.js — the MODEL SURVEY scoring fan-out (Phase D).
//
// The ONLY model-token step in the survey. One agent per model's contact-sheet (NOT per image) → five
// category cells judged from a single Read. Generation, catalog, and PDF are deterministic bash elsewhere; this
// workflow exists purely to move the *judgement* to parallel agents and return structured scores the skill
// writes back to journal.jsonl.
//
// Invoke (from the skill): Workflow({ scriptPath: "<plugin>/skills/model-survey/scripts/score-workflow.js",
//   args: { surveyDir, canon, reviewer, models: [{id, base, family, sheet, categories:[...]}] } })
// Returns: [{ model, base, family, cells:[{category,overall,...}], best_for, avoid_for, base_trait }]

export const meta = {
  name: 'model-survey-scoring',
  description: 'Score each ComfyUI model contact-sheet with the image-aesthetic lens (one agent per model)',
  phases: [{ title: 'Score', detail: 'one image-aesthetic reviewer per model contact-sheet' }],
}

const SCORECARD = {
  type: 'object',
  required: ['model', 'cells', 'best_for', 'avoid_for', 'base_trait'],
  properties: {
    model: { type: 'string' },
    base: { type: 'string' },
    family: { type: 'string' },
    cells: {
      type: 'array',
      items: {
        type: 'object',
        required: ['category', 'fit', 'adher', 'artifact', 'comp', 'docfit', 'overall', 'note'],
        properties: {
          category: { type: 'string' },
          fit: { type: 'number' }, adher: { type: 'number' }, artifact: { type: 'number' },
          comp: { type: 'number' }, docfit: { type: 'number' },
          overall: { type: 'number' }, note: { type: 'string' },
        },
      },
    },
    best_for: { type: 'array', items: { type: 'string' } },
    avoid_for: { type: 'array', items: { type: 'string' } },
    base_trait: { type: 'string' },
    settings_note: { type: 'string' },
  },
}

// args may arrive as an object or as a JSON-encoded string depending on the caller — handle both.
let A = args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
const models = (A && A.models) || []
log(`scoring ${models.length} model contact-sheets`)
phase('Score')

const results = await parallel(models.map((m) => () =>
  agent(
    `You are the PRESSROOM image-aesthetic reviewer. Read your mandate and rubric:\n` +
    `- ${A.reviewer}\n- ${A.canon}\n\n` +
    `Then Read the contact-sheet PNG for model "${m.id}" at:\n  ${m.sheet}\n\n` +
    `It shows this model's output across these categories, left to right: ${(m.categories || []).join(', ')}.\n` +
    `Model: id=${m.id}, base=${m.base}, family=${m.family}.\n\n` +
    `Score EVERY category cell on the five dimensions (fit, adher, artifact, comp, docfit; each 0–5), apply ` +
    `the hard caps (mangled anatomy ≤2; category-miss → adher ≤1; gibberish text noted), compute each cell's ` +
    `overall/100, and extract best_for / avoid_for / a base_trait sentence. Name failures concretely. ` +
    `Return the StructuredOutput scorecard.`,
    { label: `score:${m.id}`, phase: 'Score', schema: SCORECARD }
  ).then((sc) => ({ ...sc, model: sc.model || m.id, base: sc.base || m.base, family: sc.family || m.family }))
    .catch(() => null)
))

return results.filter(Boolean)
