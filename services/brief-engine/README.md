# brief-engine — daily 'what's next'

A cron container that invokes the agent's daily-brief prompt on schedule (BRIEF_CRON)
and ensures the result reaches both the vault and Telegram.

## TODO (Stage 2)
- [ ] cron entry from BRIEF_CRON in TZ
- [ ] call agent /run with the daily-brief prompt
- [ ] verify daily/YYYY-MM-DD.md written and pushed to Telegram
