#!/usr/bin/env python3
"""Witify-branded Word document: fill CONFIG, write CONTENT, run.

The brand lives in witify-template.docx (styles, cover, header, footer). This
script only replaces the cover placeholders and appends content using
the template's named styles. Requires: python-docx.
"""
import os
import shutil
import subprocess
import sys
from datetime import date

from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.enum.text import WD_BREAK
from docx.shared import Inches

FONT_DIRS = ("~/Library/Fonts", "/Library/Fonts", "/System/Library/Fonts",
             "~/.fonts", "~/.local/share/fonts", "/usr/share/fonts")


def install_fonts():
    """Copy the bundled brand fonts (fonts/) into the user's font folder when missing. Never fails.

    Source: https://fonts.google.com/specimen/Archivo
    """
    try:
        src = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts")
        target = os.path.expanduser("~/Library/Fonts" if sys.platform == "darwin" else "~/.local/share/fonts")
        present = {f.lower() for d in FONT_DIRS for _, _, fs in os.walk(os.path.expanduser(d)) for f in fs}
        copied = False
        for name in sorted(os.listdir(src)):
            if name.lower().endswith(".ttf") and name.lower() not in present:
                os.makedirs(target, exist_ok=True)
                shutil.copy(os.path.join(src, name), os.path.join(target, name))
                print(f"Installed font {name} to {target}", file=sys.stderr)
                copied = True
        if copied and sys.platform != "darwin" and shutil.which("fc-cache"):
            subprocess.run(["fc-cache", "-f"], check=False, capture_output=True)
    except Exception:
        pass


install_fonts()

# ============================================================= CONFIG
TITLE = "Server\nRequirements"                 # "\n" for line breaks
SUBTITLE = "Laravel Application Hosting on Azure"
VERSION = "1.0"
CLIENT = "Nom du client"
DATE = None                                    # None: today, in French ("10 septembre 2026")
AUTHOR = "Patrick Vigeant"
TOC = False                                    # True: "Table des matières" page after the cover
OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ============================================================= setup
MONTHS_FR = ("janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
             "septembre", "octobre", "novembre", "décembre")
today = date.today()
DATE = DATE or f"{today.day} {MONTHS_FR[today.month - 1]} {today.year}"
OUT = os.path.join(OUT_DIR, f"{TITLE.replace(chr(10), ' ')} - v{VERSION}.docx")
doc = Document(os.path.join(os.path.dirname(os.path.abspath(__file__)), "witify-template.docx"))

PLACEHOLDERS = {"{{version}}": f"Version {VERSION}", "{{title}}": TITLE, "{{subtitle}}": SUBTITLE,
                "{{client}}": CLIENT, "{{date}}": DATE, "{{author}}": AUTHOR}
for run in (r for p in doc.paragraphs for r in p.runs):
    if run.text in PLACEHOLDERS:
        run.text = PLACEHOLDERS[run.text]


def toc():
    """Heading + Word TOC field (levels 1-2) on its own page; Word fills it on open."""
    doc.add_paragraph("Table des matières", style="Title")  # not Heading 1: \o "1-2" would list it
    p = doc.add_paragraph()
    for kind, value in (("begin", None), ("instr", ' TOC \\o "1-2" \\h \\z \\u '), ("separate", None),
                        ("text", "Table des matières : ouvrir dans Word et mettre à jour les champs "
                                 "(clic droit > Mettre à jour les champs)."), ("end", None)):
        run = p.add_run(value if kind == "text" else "")
        if kind == "instr":
            el = OxmlElement("w:instrText"); el.set(qn("xml:space"), "preserve"); el.text = value; run._r.append(el)
        elif kind != "text":
            el = OxmlElement("w:fldChar"); el.set(qn("w:fldCharType"), kind); run._r.append(el)
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
    update = OxmlElement("w:updateFields")  # Word offers to refresh the field on open
    update.set(qn("w:val"), "true")
    doc.settings.element.append(update)


if TOC:
    toc()


def para(*parts, style=None, keep=False):
    """parts: strings, or (text, "b") for bold, (text, "code") for inline code.
    keep=True keeps the paragraph on the same page as what follows it."""
    p = doc.add_paragraph(style=style)
    for part in parts:
        text, kind = part if isinstance(part, tuple) else (part, None)
        run = p.add_run(text)
        run.bold = kind == "b"
        if kind == "code":
            run.style = doc.styles["Code Inline"]
    p.paragraph_format.keep_with_next = keep
    return p


def bullet(*parts, style="List Bullet"):
    return para(*parts, style=style)


def table(headers, rows, widths):
    """rows: lists of cells; a cell is a string or (main, gray sub-line)."""
    t = doc.add_table(rows=1, cols=len(headers), style="Witify Table")
    t.autofit = False
    look = t._tbl.tblPr.find(qn("w:tblLook"))  # Word applies the header-row look only with firstRow=1
    for attr, value in (("w:firstRow", "1"), ("w:noHBand", "1"), ("w:noVBand", "1")):
        look.set(qn(attr), value)
    for cell, label in zip(t.rows[0].cells, headers):
        cell.paragraphs[0].add_run(label)
    for row in rows:
        for i, value in enumerate(t.add_row().cells):
            main, sub = row[i] if isinstance(row[i], tuple) else (row[i], None)
            value.paragraphs[0].style = "Table Cell"
            value.paragraphs[0].add_run(main).bold = i == 0
            if sub:
                value.add_paragraph(sub, style="Table Sub")
    for row in t.rows:
        row._tr.get_or_add_trPr().append(OxmlElement("w:cantSplit"))  # keep rows on one page
        for cell, width in zip(row.cells, widths):
            cell.width = width
            for p in cell.paragraphs:  # keep the whole table together and with what precedes it
                p.paragraph_format.keep_with_next = row is not t.rows[-1]
    doc.add_paragraph()  # breathing room before the next block
    return t


def code(lines):
    for line in lines:
        doc.add_paragraph(line or " ", style="Code")
    doc.add_paragraph()


# ============================================================= CONTENT
# Replace everything below with the document's real content. Available:
# doc.add_heading("1. Title", level=1..3), para(...), bullet(...), table(...),
# code([...]). Number Heading 1 titles yourself. A short intro paragraph right
# before a table should use para(..., keep=True) so it stays with the table.
# With TOC = True, LibreOffice does not compute the TOC field: the placeholder
# line is expected in the PNG render; Word fills the TOC when the file opens.

doc.add_heading("1. Example section", level=1)
para(("Bold lead. ", "b"), "Normal text under a Heading 1 section.")

doc.add_heading("Example subsection", level=2)
bullet(("Bold lead", "b"), " followed by normal text and ", ("inline code", "code"), ".")
bullet("A second bullet.")

para("The table below lists the requirements.", keep=True)
table(
    headers=("Component", "Requirement"),
    rows=[
        ("OS", ("Ubuntu LTS", "A gray explanatory sub-line.")),
        ("Web server", "Nginx"),
    ],
    widths=(Inches(1.5), Inches(5.5)),
)

doc.add_heading("Example script", level=2)
code(["echo 'hello'", "# a comment"])

# =============================================================
doc.save(OUT)
print(f"Saved: {OUT}")
