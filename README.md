# Clinician AI Habits Check

A private, 18-question self-assessment of AI habits for clinicians, from [The Efficient GP](https://theefficientgp.substack.com). Based on the Clinician AI Maturity Framework v0.2 (inspired by the AI Fluency Framework by Rick Dakan, Joseph Feller and Anthropic, which is released under CC BY-NC-SA 4.0. Three habit names are borrowed from it; the definitions, levels and questions are original, with a clinical safety dimension added).

- `index.html` - the quiz. Results are calculated in the browser.
- `privacy.html` - plain-language data notice.
- `schema.sql` - Supabase table for anonymous, opt-in responses (insert-only for the public).

## Principles
For the individual only: not a grade, not for employers or appraisal. Safety flags are private prompts. Nothing is sent unless the reader ticks the consent box.

## Updating
- Post links: edit `links.json` (paste each Substack URL, then commit). No need to touch `index.html`.
- Data store: `STORE.url` and `STORE.key` (Supabase project URL and publishable key; the publishable key is designed to be public).

Licence: framework and quiz text CC BY 4.0, Dr David Stokes.
