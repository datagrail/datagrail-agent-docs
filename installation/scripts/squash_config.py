#!/usr/bin/env python

# Example Usage from root directory:
#   ./installation/scripts/squash_config.py installation/examples/agent_config.json

import json
import sys

if len(sys.argv) <= 1:
    print("Please pass in path to json config file as parameter.")
    sys.exit()


filepath = sys.argv[1]
with open(filepath, "r") as f:
    data = json.load(f)
    print(json.dumps(data))
