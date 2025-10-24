#!/bin/bash
# Compile LaTeX document with BibTeX

FILE="jaes-sample1-bibtex"

echo "==> Compiling ${FILE}.tex"
echo

echo "==> Pass 1/4: First pdflatex (generating aux file)..."
if ! pdflatex -interaction=nonstopmode "${FILE}.tex" > /dev/null 2>&1; then
    echo "Warning: pdflatex pass 1 had errors (this is normal for first pass)"
fi

echo "==> Pass 2/4: Running bibtex (processing citations)..."
if ! bibtex "${FILE}" 2>&1 | grep -v "^This is BibTeX" | grep -v "^The" | grep -v "^Database"; then
    echo "Warning: bibtex had issues"
fi

echo "==> Pass 3/4: Second pdflatex (incorporating bibliography)..."
if ! pdflatex -interaction=nonstopmode "${FILE}.tex" > /dev/null 2>&1; then
    echo "Warning: pdflatex pass 2 had errors"
fi

echo "==> Pass 4/4: Third pdflatex (finalizing cross-references)..."
if ! pdflatex -interaction=nonstopmode "${FILE}.tex" > /dev/null 2>&1; then
    echo "Warning: pdflatex pass 3 had errors"
fi

echo
if [ -f "${FILE}.pdf" ]; then
    SIZE=$(ls -lh "${FILE}.pdf" | awk '{print $5}')
    echo "✓ Success! Generated ${FILE}.pdf (${SIZE})"
    echo
    echo "To view: open ${FILE}.pdf"
else
    echo "✗ Failed to generate PDF"
    exit 1
fi
