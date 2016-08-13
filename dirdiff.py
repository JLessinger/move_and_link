from difflib import ndiff
from utility.objects import SmartHashable


class File(SmartHashable):
    def __init__(self, abs_path):
        self.abs_path = abs_path

    def __eq__(self, other):
        return self.abs_path == other.abs_path

    @staticmethod
    def is_zero(diffs):
        """

        :param diffs: (possibly nested) list, tuple or set representing diff of file metadata/contents
        :return: True IFF the diff represents 0
        """
        if isinstance(diffs, set) or isinstance(diffs, list) or isinstance(diffs, tuple):
            return all([File.is_zero(e) for e in diffs])
        return False


class RegularFile(File):
    def __init__(self, abs_path, contents):
        super(RegularFile, self).__init__(abs_path)
        self.contents = contents

    def __sub__(self, other):
        c1, c2 = self.contents, other.contents
        raw_diff = [l for l in ndiff(c1.splitlines(), c2.splitlines())]
        plus = [l[2:] for l in raw_diff if l[0] == '-']
        minus = [l[2:] for l in raw_diff if l[0] == '+']
        return (plus, minus)

class Directory(File):
    def __init__(self, abs_path, reg_files, dirs, symlinks):
        super(Directory, self).__init__(abs_path)
        self.reg_files = reg_files
        self.dirs = dirs
        self.symlinks = symlinks

    def __sub__(self, other):
        pass

class SymLink(File):
    def __init__(self, abs_path, target_abs_path):
        super(SymLink, self).__init__(abs_path)
        self.target_abs_path = target_abs_path

    def __sub__(self, other):
        if other.abs_path == self.abs_path:
            path_diff = ([], [])
        else:
            path_diff = (self.abs_path, other.abs_path)
        if other.target_abs_path == self.target_abs_path:
            target_path_diff = ([], [])
        else:
            target_path_diff = (self.target_abs_path,
                                other.target_abs_path)
        return transpose_tuple((path_diff, target_path_diff))

def transpose_tuple(t):
    return tuple(zip(*t))

if __name__ == '__main__':
    # f1 = RegularFile('f1', 'adc\ny')
    # f2 = RegularFile('f2', 'adc\nx')
    # d = f1 - f2
    # print d
    # print File.is_zero(d)
    syma = SymLink('pa1', 'pa2')
    symb = SymLink('pb1', 'pa2')
    print symb - syma