# LaTeX Template — Print-Quality A4 Article With Diagrams

> A copy-pasteable LaTeX preamble plus the figure-inclusion patterns that
> obey the charting matrix. Tested against `texlive-base` +
> `texlive-latex-recommended` (no `tikz`, no `fontawesome`, no
> `tcolorbox`). Compiles cleanly with `pdflatex` or `lualatex`.

---

## 1. Preamble (copy-paste)

```latex
\documentclass[11pt,a4paper,twoside]{article}

% --- Geometry: A4, 135mm × 215mm text block ---
\usepackage[
  a4paper,
  textwidth=135mm,
  textheight=215mm,
  inner=30mm,
  outer=20mm,
  top=30mm,
  bottom=30mm,
  headsep=8mm
]{geometry}

% --- Encoding & typography ---
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage{textcomp}
\usepackage{amssymb}
\usepackage{pifont}
\usepackage{microtype}
\usepackage[parfill]{parskip}
\setlength{\parskip}{0.55em}
\linespread{1.10}

% --- Colour palette (matches Graphviz palette in graphviz-patterns.md) ---
\usepackage[table,dvipsnames]{xcolor}
\definecolor{accent}{HTML}{0969da}
\definecolor{accent-dark}{HTML}{0a3069}
\definecolor{accent-soft}{HTML}{eef4ff}
\definecolor{warn}{HTML}{9a6700}
\definecolor{warn-soft}{HTML}{fff8c5}
\definecolor{green}{HTML}{1a7f37}
\definecolor{green-soft}{HTML}{dafbe1}
\definecolor{red}{HTML}{cf222e}
\definecolor{red-soft}{HTML}{ffd1cc}
\definecolor{purple}{HTML}{8250df}
\definecolor{purple-soft}{HTML}{fce8ff}
\definecolor{ink}{HTML}{0d1117}
\definecolor{rule-color}{HTML}{1f6feb}
\definecolor{quote-bar}{HTML}{8250df}
\definecolor{sidebar-bg}{HTML}{f6f8fa}
\definecolor{muted}{HTML}{57606a}

% --- Tables ---
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{array}
\usepackage{tabularx}
\usepackage{colortbl}
\renewcommand{\arraystretch}{1.30}

% --- Graphics & captions ---
\usepackage{graphicx}
\usepackage{caption}
\captionsetup{
  font=small,
  labelfont={bf,color=accent},
  textfont=it,
  skip=4pt,
  justification=raggedright,
  singlelinecheck=false
}

% --- Code listings ---
\usepackage{listings}
\lstdefinestyle{fmcode}{
  basicstyle=\ttfamily\footnotesize\color{ink},
  backgroundcolor=\color{sidebar-bg},
  commentstyle=\itshape\color{muted},
  keywordstyle=\bfseries\color{accent},
  stringstyle=\color{green},
  showstringspaces=false,
  frame=leftline,
  framerule=2pt,
  rulecolor=\color{accent},
  xleftmargin=1em,
  framesep=8pt,
  aboveskip=0.8em,
  belowskip=0.8em,
  breaklines=true,
  breakatwhitespace=true,
  columns=fullflexible,
}
\lstset{style=fmcode}

% --- Links ---
\usepackage[hidelinks,colorlinks=true,urlcolor=accent,linkcolor=accent-dark]{hyperref}
\usepackage{url}

% --- Running heads & section styling ---
\usepackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[LE]{\small\itshape\color{muted}\thepage \quad ARTICLE TITLE}
\fancyhead[RO]{\small\itshape\color{muted}\nouppercase{\rightmark} \quad \thepage}
\fancyfoot[C]{}
\renewcommand{\headrulewidth}{0.4pt}

% --- Section heading colours ---
\makeatletter
\renewcommand{\section}{\@startsection{section}{1}{\z@}%
  {3ex plus 1ex minus .2ex}{1.6ex plus .2ex}%
  {\normalfont\Large\bfseries\color{accent-dark}}}
\renewcommand{\subsection}{\@startsection{subsection}{2}{\z@}%
  {2.2ex plus 1ex minus .2ex}{1.0ex plus .2ex}%
  {\normalfont\large\bfseries\color{accent}}}
\makeatother

% --- Orphan-section-heading prevention (hand-rolled \needspace) ---
% \sectionneeds{height} — if less than {height} remains on the page,
% start a new page so the section heading does not orphan.
\makeatletter
\newcommand{\sectionneeds}[1]{%
  \par\dimen@=\pagegoal\advance\dimen@ by -\pagetotal\relax%
  \ifdim\dimen@<#1\relax\clearpage\fi%
}
\makeatother

% --- Pullquote and callout environments ---
\newenvironment{pullquote}{%
  \par\vspace{1em}%
  \begingroup
  \leftskip=2em\rightskip=0.5em%
  \itshape\large\color{accent-dark}%
  \noindent\hspace{-1.4em}\color{quote-bar}\rule[-0.3em]{2.5pt}{1.4em}%
  \hspace{0.6em}\color{accent-dark}\itshape%
}{\par\endgroup\par\vspace{1em}}

\newsavebox{\calloutbox}
\newenvironment{callout}[1][CALLOUT]{%
  \par\vspace{0.6em}%
  \begin{lrbox}{\calloutbox}%
  \begin{minipage}[t]{\dimexpr\linewidth-1.6em}%
  \textbf{\color{warn}\small\MakeUppercase{#1}}\par\vspace{0.3em}%
  \color{ink}\small\ignorespaces
}{%
  \end{minipage}%
  \end{lrbox}%
  \noindent\fcolorbox{warn}{warn-soft}{\usebox{\calloutbox}}%
  \par\vspace{0.6em}%
}
```

---

## 2. The figure inclusion idiom

For **every full-page figure** (height ≥ 0.70\textheight):

```latex
\clearpage
\begin{figure}[t]
  \centering
  \includegraphics[
    width=\linewidth,
    height=0.86\textheight,
    keepaspectratio
  ]{diagrams/NN-name.pdf}
  \caption{Caption text. End with a description of what the
    diagram contributes.}
\end{figure}
\clearpage
```

For **inline figures** (height < 0.55\textheight):

```latex
\begin{figure}[h]
  \centering
  \includegraphics[
    width=\linewidth,
    height=0.55\textheight,
    keepaspectratio
  ]{diagrams/NN-name.pdf}
  \caption{...}
\end{figure}
```

### Three non-negotiable parameters

| Parameter | Rationale |
|-----------|-----------|
| `width=\linewidth` | Cap at the page text width |
| `height=0.86\textheight` (or 0.55) | Cap at the page text height so the figure cannot run off |
| `keepaspectratio` | Preserve the diagram's intended proportions |

**Never use** `width=\linewidth` alone on a non-trivial diagram. It is
the single most common cause of "diagram disappears off the bottom of
the page" feedback.

---

## 3. Forbidden / unavailable packages

These packages are NOT in `texlive-recommended` and should not be
required by the preamble (substitutions in parentheses):

- `tikz` (use Graphviz `.dot` + `\includegraphics{*.pdf}`)
- `fontawesome` / `fontawesome5` (use `pifont`'s `\ding{...}` glyphs)
- `tcolorbox` (use the `callout` environment defined above)
- `mdframed` (same)
- `framed` (use the `callout` environment defined above)
- `titlesec` (use the `\makeatletter / \renewcommand{\section}` block)
- `wrapfig` (use plain `figure` environments with `\clearpage`)
- `enumitem` (set `\parsep` and `\itemsep` directly)
- `minted` (use `listings` with the `fmcode` style above)

---

## 4. Build sequence

```bash
# Generate all diagrams first
cd <article-dir>/build/diagrams
for f in *.dot; do dot -Tpdf "$f" -o "${f%.dot}.pdf"; done

# Compile the article (3 passes for TOC + cross-refs)
cd ..
pdflatex -interaction=nonstopmode <article-name>.tex
pdflatex -interaction=nonstopmode <article-name>.tex
pdflatex -interaction=nonstopmode <article-name>.tex

# Deploy to article folder
cp <article-name>.pdf ../<article-name>.pdf
```

Use `scripts/build-pdf.sh` from this skill for a one-command build.

---

## 5. Page-break rules at a glance

| Section type | Page-break treatment |
|--------------|---------------------|
| Title page | Own page (use `titlepage` environment) |
| Epigraph / dedication | Own page (`\thispagestyle{empty}\null\vfill...\vfill\null\clearpage`) |
| Table of contents | Own page |
| Major section (Part I, II, …) | `\clearpage` before |
| Full-page figure | `\clearpage` before AND after |
| Inline figure | No clearpage; let it float |
| Highest-impact paragraph | `\clearpage` before; consider a callout box |
| Colophon | Own page (`\clearpage` before) |
| Each appendix | `\clearpage` before |
| **Subsection (`\subsection`) heading** | **Prepend `\sectionneeds{6cm}`** to prevent orphan-at-bottom |

### Orphan-heading prevention (Rule R-A2)

After compiling, scan the PDF for subsection headings within the **last
6 cm** of any page where their content spills to the next page. For
each such heading, prepend `\sectionneeds{6cm}` (or `\clearpage` for
the harder cases):

```latex
\sectionneeds{6cm}
\subsection{The Subsection With An Orphan Heading}
First line of content...
```

**Exception:** If a section is more than one page long, content overrun
is unavoidable; do not add `\sectionneeds` (it would just shift the
overrun, not eliminate it). The rule applies only to short sections
that *could* fit entirely on one page.

The hand-rolled `\sectionneeds{height}` command is defined in §1
(Preamble) — it is portable and does not require the `needspace`
package.

---

## 6. Common errors & fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `wrapfig.sty not found` | Package not installed | Remove `\usepackage{wrapfig}`; restructure with `figure` + `\clearpage` |
| `! Undefined control sequence \checkmark` | `amssymb` missing | Add `\usepackage{amssymb}` or use `\ding{51}` |
| `framed.sty not found` | Package not installed | Use the `callout` environment from §1 |
| Table widths warning | longtable needs another pass | Run `pdflatex` again (always 3× total) |
| Phase name broken across lines | Single-cell text too wide | Insert `\newline` between numeral and name inside cell |
| Column overlap in long table | `\tabcolsep` too small | `\setlength{\tabcolsep}{10pt}` before the table |
| Monospace identifier (e.g. `ds-step-0-plan`) overruns into next column | `\texttt` does not break at hyphens by default | Apply column-level `>{\ttfamily\footnotesize}` (drop per-cell `\texttt{}`); OR use `\nolinkurl{...}`; AND cap table width at ≤ 0.75 of `\linewidth` (per Rule R-A3a) |
| Section heading still orphaned at bottom of page despite `\sectionneeds` | Soft threshold passed but content overflowed anyway | Replace with hard `\clearpage` (per Lesson 0017) |
