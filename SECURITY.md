# Security Policy

## The promise

mdbrowse exists so you can **open a Markdown file you did not write** — one you
downloaded, cloned, or were sent — and read it without thinking about it.

That promise is load-bearing, because of where the rendered page runs. Once mdbrowse
is your default `.md` handler, a double-click renders the document on a `file://`
origin, sitting next to your own files. Markdown is allowed to contain raw HTML, and
`innerHTML` will happily fire an `onerror` handler. So the page is sanitized with
[DOMPurify](https://github.com/cure53/DOMPurify) before anything reaches the DOM.

**Anything that gets script to run from a `.md` file is a vulnerability**, and I want
to hear about it.

## What counts

- Executing JavaScript from a `.md` file — event handlers, `javascript:` URLs, SVG,
  `<iframe>`, anything DOMPurify was supposed to strip.
- **Escaping the inline `<script>` block.** The page embeds link and image maps as JS
  literals. A crafted path that closes that element early drops its tail into the page
  as HTML — *past* the sanitizer, which only guards what `innerHTML` receives. This has
  happened; it is why every emitted value goes through one escaping helper.
- Reading or exfiltrating files the user did not open.
- A crafted document that makes the script write outside its cache directory.
- Any way `install.sh` / `uninstall.sh` can be induced to clobber files it does not own.

## What doesn't

These are known, intentional, and documented — please don't file them as
vulnerabilities:

- **The rendered page needs JavaScript.** Markdown is parsed client-side by design.
- **The cache is world-readable-ish.** Rendered pages land in `~/.cache/mdbrowse` (or
  `~/mdbrowse-cache` when your browser is sandboxed) with your normal umask. If a
  document is secret, its rendered copy is exactly as secret as the original.
- **mdbrowse follows relative links and reads the files they point at.** That is the
  feature. It stays within the filesystem, reads nothing over the network, and only
  pre-renders `.md` targets that already exist on disk.
- **Bugs in the bundled libraries** (marked, DOMPurify, github-markdown-css) belong
  upstream — but do tell me, so the vendored copy gets updated here too.
- Linux-only; no Windows or macOS support.

## Reporting

**Please do not open a public issue for a vulnerability.**

Use GitHub's private reporting: **Security → Report a vulnerability** on this repo.
It is private until a fix ships.

A proof of concept helps enormously — a `.md` file that demonstrates the problem is
worth more than a description of it. If it depends on a particular filesystem layout
(a directory with an unusual name, say), include that.

I maintain this in my spare time, so I can't promise a response time. I will confirm
that I received your report, tell you whether I consider it a vulnerability and why,
and credit you when it is fixed unless you'd rather I didn't.

## Supported versions

`main` only. There are no releases yet; if you are running mdbrowse, you are running
whatever `git pull` last gave you.
