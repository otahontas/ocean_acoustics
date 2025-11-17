#!/bin/bash
# Compile LaTeX document with BibTeX

FILE="main"

echo "==> Compiling ${FILE}.tex"
echo

echo "==> Pass 1/4: First pdflatex (generating aux file)..."
pdflatex -interaction=nonstopmode "${FILE}.tex" > /dev/null 2>&1

echo "==> Pass 2/4: Running bibtex (processing citations)..."
bibtex "${FILE}" > /dev/null 2>&1

echo "==> Pass 3/4: Second pdflatex (incorporating bibliography)..."
pdflatex -interaction=nonstopmode "${FILE}.tex" > /dev/null 2>&1

echo "==> Pass 4/4: Third pdflatex (finalizing cross-references)..."
pdflatex -interaction=nonstopmode "${FILE}.tex" > /dev/null 2>&1

echo
if [ -f "${FILE}.pdf" ]; then
    SIZE=$(ls -lh "${FILE}.pdf" | awk '{print $5}')

    # Check for font warnings (non-critical)
    FONT_WARNINGS=$(grep -c "Font.*not loadable" "${FILE}.log" 2>/dev/null || echo 0)

    echo "✓ Success! Generated ${FILE}.pdf (${SIZE})"

    if [ "$FONT_WARNINGS" -gt 0 ]; then
        echo "  Note: ${FONT_WARNINGS} missing fonts (harmless - using substitutes)"
        echo "  To silence: sudo tlmgr install jknappen"
    fi

    echo
    echo "To view: open ${FILE}.pdf"
else
    echo "✗ Failed to generate PDF"
    echo "Check ${FILE}.log for errors"
    exit 1
fi
