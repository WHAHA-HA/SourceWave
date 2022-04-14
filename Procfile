web: bundle exec passenger start -p $PORT --max-pool-size 5
worker: bundle exec sidekiq -c 25
processlinks: bundle exec sidekiq -q process_links -c 25
verifydomains: bundle exec sidekiq -q verify_domains -c 25
