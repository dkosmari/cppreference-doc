#!/usr/bin/env python3
'''
    Copyright (C) 2013  Povilas Kanapickas <povilas@radix.lt>

    This file is part of cppreference-doc

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.
'''

import argparse

from index_transform.devhelp import transform_devhelp


def main():
    parser = argparse.ArgumentParser(prog='index2devhelp')
    parser.add_argument('--base', type=str,
                        help='path to the location of the book')
    parser.add_argument('--chapters', type=str,
                        help='path to the chapters file to include')
    parser.add_argument('--title', type=str,
                        help='title of the book')
    parser.add_argument('--name', type=str,
                        help='name of the package')
    parser.add_argument('--rel', type=str,
                        help='link relative to the root of the documentation')
    parser.add_argument('--src', type=str,
                        help='path of the source file')
    parser.add_argument('--dst', type=str,
                        help='the path of the destination file')
    parser.add_argument('--lang', type=str,
                        help='the language of the book (c, c++, etc)')
    args = parser.parse_args()

    with open(args.dst, 'wb') as out_f:
        output = transform_devhelp(title = args.title,
                                   name = args.name,
                                   base = args.base,
                                   rel = args.rel,
                                   chapters = args.chapters,
                                   src = args.src,
                                   language = args.lang)
        out_f.write(output)


if __name__ == '__main__':
    main()
