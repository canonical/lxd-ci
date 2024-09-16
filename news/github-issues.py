#!/usr/bin/python3

import json
import sys
from urllib.parse import quote
from urllib.request import urlopen

# Convenience functions
def get_json(url):
    return json.loads(urlopen(url).read().decode())

# Basic arg parsing
if len(sys.argv) != 4:
    print("Usage: %s <repo> <date_start> <date_end>", sys.argv[0])
    sys.exit(1)

repo = sys.argv[1]
start = sys.argv[2]
end = sys.argv[3]

# Get data

url = "https://api.github.com/search/issues?q=repo:%s+is:merged+is:pr+merged:%s..%s&per_page=100&sort=created&order=asc" % (repo, start, end)

prs = get_json(url)

if len(prs["items"]) <= 0:
   print("* Nothing to report this week")

for pr in prs["items"]:
    print(" - [%s](%s)" % (pr["title"], pr["html_url"]))
