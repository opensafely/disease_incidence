import ast
import csv
from pathlib import Path


# load as dict with code as key for easier later deduping
def load_codelist(path: Path) -> dict:
    return {
        c["code"]: {k: v for k, v in c.items() if k != "code"}
        for c in list(csv.DictReader(path.open()))
    }


def write_fixed_codelist(codelist: dict, path: Path):
    def output_path(path: Path) -> Path:
        return Path("local_codelists") / (path.stem + "_fixed" + path.suffix)

    codelist_output = []

    for code, values in codelist.items():
        for modifier in ["modifier_4", "modifier_5"]:
            if modifier_term := values.get(modifier):
                values["term"] += f" - {modifier_term}"
        row = {"code": code} | values
        codelist_output.append(row)

    fixed_path = output_path(path)
    with fixed_path.open("w") as f:
        writer = csv.DictWriter(f, fieldnames=["code", "term"], extrasaction="ignore")
        writer.writeheader()
        writer.writerows(sorted(codelist_output, key=lambda x: x["code"]))

    return fixed_path


# get child codes of every code in codelist, add in if missing
def fix_missing_children(codelist: dict, icd_combined: list) -> dict:
    def find_children(code: str) -> dict:
        return {
            i["code"]: {k: v for k, v in i.items() if k != "code"}
            for i in icd_combined
            if i["parent_id"] == code
        }

    child_codes = dict()
    for code in codelist:
        children = find_children(code)
        # don't add if sibling codes found - likely purposeful exclusion
        if not any(set(codelist.keys()).intersection(children.keys())):
            child_codes |= find_children(code)

    # prioritise original codelist entries over anything we find
    return child_codes | codelist


# get codes with identical term to existing term (i.e 2016 vs 2019)
def fix_version_differences(codelist: dict, icd_combined: list) -> dict:
    def get_alternate_codes(term: str) -> dict:
        return {
            i["code"]: {k: v for k, v in i.items() if k != "code"}
            for i in icd_combined
            if i["term"] == term
        }

    codes_by_term = dict()
    for term in [v["term"] for v in codelist.values()]:
        codes_by_term |= get_alternate_codes(term)

    # prioritise original codelist entries over anything we find
    return codes_by_term | codelist


def main():
    with Path("icd_combined_2026-02-05.csv").open() as f:
        icd_combined = list(csv.DictReader(f))

    codelists_ehrQL_path = Path("analysis/codelists_ehrQL.py")
    codelists_ehrQL = codelists_ehrQL_path.read_text()

    tree = ast.parse(codelists_ehrQL)
    icd = [
        t
        for t in tree.body
        if isinstance(t, ast.Assign)
        and t.targets[0].id.endswith("_icd")
        and isinstance(t.value, ast.Call)
        and t.value.func.id == "codelist_from_csv"
    ]

    icd_codelist_paths = [Path(c) for c in [i.value.args[0].value for i in icd]]
    fixed_codelists = []
    for icd_codelist_path in icd_codelist_paths:
        codelist = load_codelist(icd_codelist_path)
        fixed_codelist = fix_missing_children(codelist, icd_combined)
        fixed_codelist = fix_version_differences(fixed_codelist, icd_combined)
        if fixed_codelist != codelist:
            fixed_path = write_fixed_codelist(fixed_codelist, icd_codelist_path)
            fixed_codelists.append((icd_codelist_path, fixed_path))

    for old_path, new_path in fixed_codelists:
        codelists_ehrQL = codelists_ehrQL.replace(str(old_path), str(new_path))

    Path("analysis/codelists_ehrQL.py").write_text(codelists_ehrQL)


if __name__ == "__main__":
    main()
