#!/usr/bin/env python3
"""
Smoke-check the renderer by posting a render request.
"""

import argparse
import json
import random
import time
import urllib.request


#============================================
def parse_args() -> argparse.Namespace:
	"""
	Parse command-line arguments.
	"""
	parser = argparse.ArgumentParser(
		description="Post a render request to the renderer API and verify output."
	)
	parser.add_argument(
		"-b",
		"--base-url",
		dest="base_url",
		default="http://localhost:3000",
		help="Base renderer URL (default: http://localhost:3000).",
	)
	parser.add_argument(
		"-p",
		"--path",
		dest="source_file_path",
		default="private/myproblem.pg",
		help="Problem file path to render (default: private/myproblem.pg).",
	)
	parser.add_argument(
		"-s",
		"--seed",
		dest="problem_seed",
		type=int,
		default=1234,
		help="Problem seed (default: 1234).",
	)
	parser.add_argument(
		"-o",
		"--output-format",
		dest="output_format",
		default="classic",
		help="Output format template id (default: classic).",
	)
	args = parser.parse_args()
	return args


#============================================
def build_payload(args: argparse.Namespace) -> dict:
	"""
	Build the JSON payload for the render request.
	"""
	payload = {
		"sourceFilePath": args.source_file_path,
		"problemSeed": args.problem_seed,
		"outputFormat": args.output_format,
	}
	return payload


#============================================
def request_render(base_url: str, payload: dict) -> dict:
	"""
	Post to /render-api and return the decoded JSON response.
	"""
	url = f"{base_url}/render-api"
	body = json.dumps(payload).encode("utf-8")
	headers = {"Content-Type": "application/json"}

	# Respect the repo guidance to throttle API calls.
	time.sleep(random.random())

	request = urllib.request.Request(url, data=body, headers=headers, method="POST")
	with urllib.request.urlopen(request, timeout=30) as response:
		raw_body = response.read().decode("utf-8")
		json_body = json.loads(raw_body)
	return json_body


#============================================
def main() -> None:
	"""
	Run the smoke check against the renderer.
	"""
	args = parse_args()
	base_url = args.base_url.rstrip("/")
	payload = build_payload(args)
	response = request_render(base_url, payload)

	rendered_html = response.get("renderedHTML", "")
	if rendered_html and "Problem" in rendered_html:
		print(f"[OK] {args.source_file_path} seed={args.problem_seed}")
	else:
		raise RuntimeError(
			f"[FAIL] {args.source_file_path} missing expected content"
		)

	print("pg-smoke complete")


if __name__ == "__main__":
	main()
