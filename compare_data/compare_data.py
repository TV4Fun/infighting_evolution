import csv
import itertools
from typing import Mapping


def make_csv_dict(csv_reader: csv.reader, label_fields) -> Mapping[tuple, tuple]:
    return {tuple(row[:label_fields]): tuple(row[label_fields:]) for row in csv_reader}


def read_csv_file(file_name: str, header_lines: int, label_fields: int) -> csv.reader:
    with open(file_name, 'r', newline='') as fp:
        fp = itertools.islice(fp, header_lines, None)
        csv_reader = csv.reader(fp)
        return make_csv_dict(csv_reader, label_fields)


def compare_data(old_file: str, new_file: str, header_lines: int = 0, label_fields: int = 1):
    old_dict = read_csv_file(old_file, header_lines, label_fields)
    new_dict = read_csv_file(new_file, header_lines, label_fields)
    return old_dict == new_dict
