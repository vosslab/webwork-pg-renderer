# Usage guide for instructors

## Why this tool exists

ADAPT errors are often opaque. This renderer shows line level errors and supports fast iteration
before you import into ADAPT.

## Quickstart workflow

Use the same cycle every time: run, check, adjust, rerun.

- Put your problem under `private/` on your computer.
- Open the file in the renderer and set a seed.
- Render, fix issues, and repeat until it looks right.
- Import the final file into ADAPT.

## Optional but recommended: local renderer setup

This is a copy and paste setup. You do not need to learn Docker.

### Option A: run locally

- Start the container:

```bash
podman-compose build --no-cache && podman-compose up -d
```

- Open the renderer at `http://localhost:3000` (POST `/` for renders; `/render-api` remains supported).
- Stop it later with `podman-compose down`.

### Option B: skip local setup

If you want to move fast, start with the ADAPT preview and only use this renderer when
something breaks or looks odd.

## Reproducibility and the seed

The seed matters because it lets you reproduce a broken variant exactly. If a render looks
wrong, reuse the same seed until you have fixed the issue.

## Where files live

Files in `private/` on your computer appear inside the tool as `private/`.
For example, `private/myproblem.pg` is the same as your local file
`private/myproblem.pg`.

## Student view checks

These settings help you decide if you are debugging or reviewing what students see.

- `permissionLevel`: switch between student and instructor style output.
- `showHints` and `showSolutions`: verify what is visible to students.
- `outputFormat`: confirm the simplest format before using more complex formats.

## When to use local testing

| Situation | Use local testing |
| --- | --- |
| ADAPT says "error" with no details | Render locally to see line level errors |
| Randomized problem behaves inconsistently | Set a seed and render several variants |
| You changed macros or contexts | Render once locally before importing |
| You are trying a new interaction type | Confirm it renders in the simplest format first |

## Troubleshooting basics

- Check `http://localhost:3000/health` to confirm the renderer is up.
- If it is down, check container logs with `podman-compose logs -f`.
- Two common failures are the wrong file path and missing macros.

## Maintainers only

If you maintain the renderer, start with the [code architecture guide](CODE_ARCHITECTURE.md)
and the [file structure guide](FILE_STRUCTURE.md).
