"""Stellt beim Artifact-Export verlorene Quellfilter/Namen ohne Zelländerung wieder her."""
from pathlib import Path
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape, quoteattr

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path('C:/Users/Allmo/OneDrive/Desktop/Roblox Idel Mine game/Balancing.xlsx')
model_date = json.loads((ROOT / 'tools/balancing_20261109/model.json').read_text(encoding='utf-8'))['generated_date']
TARGET = ROOT / 'outputs' / f'balancing-{model_date.replace("-", "")}' / 'Balancing_Neuentwurf.xlsx'
NS = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

with zipfile.ZipFile(SOURCE) as original, zipfile.ZipFile(TARGET) as current:
    source_book = ET.fromstring(original.read('xl/workbook.xml'))
    names = source_book.find('s:definedNames', NS)
    assert names is not None and len(names) == 5
    book_text = current.read('xl/workbook.xml').decode('utf-8')
    prefix = re.search(r'<((?:[A-Za-z_]\w*:)?)(?:workbook)\b', book_text).group(1)
    source_sheet_names = [s.get('name') for s in source_book.find('s:sheets', NS)]
    current_sheet_names = [s.get('name') for s in ET.fromstring(book_text).find('s:sheets', NS)]
    assert current_sheet_names[:len(source_sheet_names)] == source_sheet_names
    filters = {}
    for index in range(1, len(source_sheet_names)+1):
        file = f'xl/worksheets/sheet{index}.xml'
        flt = ET.fromstring(original.read(file)).find('s:autoFilter', NS)
        if flt is not None:
            assert len(flt) == 0, 'Komplexe Filter brauchen separate Behandlung'
            filters[file] = flt.get('ref')
    assert len(filters) == 5
    if f'<{prefix}definedNames' not in book_text:
        fragment = f'<{prefix}definedNames>' + ''.join(
            f'<{prefix}definedName ' + ' '.join(f'{k}={quoteattr(v)}' for k,v in item.attrib.items())
            + '>' + escape(item.text or '') + f'</{prefix}definedName>' for item in names
        ) + f'</{prefix}definedNames>'
        match = re.search(r'<'+re.escape(prefix)+r'calcPr\b', book_text)
        position = match.start() if match else book_text.rfind(f'</{prefix}workbook>')
        assert position > 0
        book_text = book_text[:position] + fragment + book_text[position:]
    views = source_book.find('s:bookViews', NS)
    if views is not None and f'<{prefix}bookViews' not in book_text:
        view_fragment = f'<{prefix}bookViews>' + ''.join(f'<{prefix}workbookView '+' '.join(f'{k}={quoteattr(v)}' for k,v in item.attrib.items())+' />' for item in views) + f'</{prefix}bookViews>'
        book_text = book_text.replace(f'<{prefix}sheets>',view_fragment+f'<{prefix}sheets>',1)
    calculation = source_book.find('s:calcPr', NS)
    if calculation is not None and f'<{prefix}calcPr' not in book_text:
        calc_fragment = f'<{prefix}calcPr '+' '.join(f'{k}={quoteattr(v)}' for k,v in calculation.attrib.items())+' />'
        book_text = book_text.replace(f'</{prefix}workbook>',calc_fragment+f'</{prefix}workbook>',1)
    replacements = {'xl/workbook.xml': book_text.encode('utf-8')}
    for file, reference in filters.items():
        text = current.read(file).decode('utf-8')
        sheet_prefix = re.search(r'<((?:[A-Za-z_]\w*:)?)(?:worksheet)\b', text).group(1)
        if f'<{sheet_prefix}autoFilter' not in text:
            closing = f'</{sheet_prefix}sheetData>'
            assert closing in text
            text = text.replace(closing, closing+f'<{sheet_prefix}autoFilter ref="{reference}"/>', 1)
        assert ET.fromstring(text).find('s:autoFilter', NS).get('ref') == reference
        replacements[file] = text.encode('utf-8')
    assert len(ET.fromstring(book_text).find('s:definedNames', NS)) == 5
    temporary = TARGET.with_suffix('.metadata.tmp')
    with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED) as result:
        for entry in current.infolist():
            result.writestr(entry, replacements.get(entry.filename, current.read(entry.filename)))
temporary.replace(TARGET)
print('Quell-Metadaten wiederhergestellt: fünf AutoFilter und fünf lokale Namen; Zellen unverändert.')
