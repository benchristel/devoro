# Devoro

Devoro is a web crawler that has evolved to ferret out interesting pages that
probably aren't going to come up in a Google search.

## Usage

You'll need Redis, Ruby, and Bundler.

In the `redis-cli`, add at least one URL as a starting point
for the crawler:

```
ZINCRBY ranked_urls 20 'http://example.com'
```

Then start the crawler:

```
ruby main.rb
```

## Output

A list of crawled URLs, with ratings 0-20, is continuously
output to `pages.tsv`. `links.log` can be used to see
what links to what, and `rejects.log` is useful for seeing
which URLs weren't crawled and why.

`links.log` and `rejects.log` get big quickly and are not
rotated, so be sure to delete them occasionally.
