# Hackathon IFM

A data powered dashboard that turns scattered client feedback into insights the
people who actually build the products can act on.

## The problem

Today the voice of the client reaches the people who design and build new
products as a monthly email, usually a PowerPoint or an Excel file that
"apparently" summarizes what clients want.

This is broken in three ways:

* **Lossy.** Rich, nuanced feedback gets flattened into a few bullet points.
* **One way.** It is a report, not a tool. The recipient cannot ask follow up
  questions, filter, or dig into *why*.
* **Disempowering.** The product developer cannot explore the data, so they
  build against a second hand summary instead of the real signal.

The result is that communication is lost between the client and the person who
could actually fulfill their desires.

<details>
<summary>the real issue:</summary>

<img src="https://images3.memedroid.com/images/UPLOADED629/659ba4b20e7fc.jpeg" alt="excel meme">

</details>

## Our solution

Replace the monthly email with a living dashboard built for the product
developer and designer. Instead of reading someone else's summary, they can:

* **Filter and organize** feedback by product, collection, season, region,
  channel (online vs in store), client segment, sentiment, and more.
* **Analyze and visualize** trends, recurring requests, likes and dislikes, and
  emerging signals interactively, not as a static slide.
* **Ask in plain language.** A local AI model translates questions such as
  "What did clients dislike about the spring jackets?" into queries and
  generates the matching chart, with no data leaving the building.

The feedback loop becomes two way and explorable instead of one way and
flattened.

> **Primary user:** the product developer and designer, the person who today
> receives the feedback email and has to act on it.

## Features

### 1. Feedback dashboard (core)

* Ingest feedback from multiple sources into one model.
* Filter and combine by product, season, segment, sentiment, region, channel
  (online vs in store), and date.
* Visualizations: trend lines, top requests, sentiment breakdown, comparisons.
* Saved views so a developer can return to their slice instantly.

### 2. Local AI insights (differentiator)

* Natural language to query to chart, powered by a local LLM. Privacy first:
  client data never leaves the org.
* Auto generated summaries such as "Top 5 things clients asked for this month."
* Surfacing of non obvious correlations and emerging trends.

### 3. Seller chatbot (bonus)

* For boutique sellers to log day to day interactions in seconds. After a sale
  or any client interaction, the seller just tells the chatbot what happened.
* The chatbot classifies each entry on its own:
  * **General feedback** vs **feedback tied to a specific sale or interaction.**
  * The exact **products** involved, extracted from what the seller says.
* Turns informal in store observations ("clients keep asking for X") into a
  structured, queryable database of what clients want, like, and dislike.

### 4. Client chatbot (bonus)

* Opt in only, after the client authorizes it.
* Captures the post purchase experience in conversation instead of a survey
  form.
* Feeds structured signal straight into the dashboard.

### 5. Web and analytics data

* Bring in insights from the web team: website analytics such as Google
  Analytics, traffic, and online behavior.
* Tag this data with the online channel and a region so the dashboard can slice
  feedback by channel (online vs in store) and compare the two.
* Enrich these signals with AI generated insights alongside first party
  feedback.

<details>
<summary>dev team in action:</summary>

<img src="https://media.tenor.com/Rnj5Mu73rPAAAAAM/south-park-warcraft.gif" alt="meme pc guy">

</details>

## Build plan (phased)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 0 | Synthetic dataset, data model, and seeds | ☐ |
| 1 | Dashboard: filter, organize, visualize | ☐ |
| 2 | Local AI: natural language query to chart | ☐ |
| 3 | Seller chatbot to structured feedback | ☐ |
| 4 | Client chatbot (opt in) | ☐ |
| 5 | Web and analytics data (Google Analytics) plus AI insights | ☐ |

Minimum viable demo is Phase 1. Everything after that is upside.

## Tech stack

* **Framework:** Ruby on Rails 8
* **Frontend:** Hotwire (Turbo and Stimulus), server rendered, minimal JS
* **Styling:** Tailwind CSS
* **Database:** PostgreSQL
* **Charts:** Chartkick with Chart.js (or ApexCharts)
* **Local AI:** [Ollama](https://ollama.com) running a local LLM such as
  Llama 3, called from Rails, keeping all client data on premises
* **Background jobs:** Solid Queue for ingestion and AI calls

Running the model locally is both a privacy guarantee and a selling point to the
judges, since client feedback is sensitive.

## Data model (draft)

Synthetic, fashion retail flavored data that we generate ourselves.

* **Product:** name, category, collection, season, price tier
* **Client:** anonymized segment, region, loyalty tier
* **Feedback:** free text, sentiment, channel (online or in store), kind
  (general or tied to a sale), date, belongs to a Product and a Client
* **Interaction:** a logged sale or client contact from the seller chatbot,
  links the feedback to the products involved
* **WebSignal:** website analytics from the web team (traffic, behavior),
  tagged online and by region
* **Insight:** AI generated summary linked to a filter or query
* **Source:** where the data came from (import, client bot, seller bot, web team)

We will write a seed generator that produces realistic feedback (a mix of
likes, dislikes, and feature requests) so the dashboard has something
convincing to show on day one.

## Getting started

```bash
# Prereqs: Ruby 3.x, PostgreSQL, and Ollama (for AI features)
bundle install
rails db:create db:migrate db:seed   # seeds synthetic feedback
bin/dev                              # boots Rails plus the Tailwind watcher

# For AI features:
ollama pull llama3
```

Then visit `http://localhost:3000`.

## Demo script

The story we tell the judges:

1. "Here is how it works today." Show a flat PowerPoint slide of feedback.
2. Open the app. Same data, now filterable and visual.
3. Filter to one collection. A trend jumps out that the slide hid.
4. Type a question in plain language and the AI returns a chart instantly.
5. Show a seller logging an interaction via chatbot and it appears live in the
   dashboard. The loop is closed.
