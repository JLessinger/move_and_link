import collections
from difflib import ndiff
from utility.objects import SmartHashable


class File(SmartHashable):
    def __init__(self, name):
        super(File, self).__init__()
        self._name = name

    @staticmethod
    def is_zero(diffs):
        """

        :param diffs: (possibly nested) list, tuple or set representing diff of file metadata/contents
        :return: True IFF the diff represents 0
        """
        if isinstance(diffs, str):
            return len(diffs) == 0
        if isinstance(diffs, collections.Container):
            for d in diffs:
                if d == diffs:
                    raise ValueError('cannot check against 0: non-str self-containing value: {0}'.format(d))
                else:
                    if not File.is_zero(d):
                        return False
        return True

    @staticmethod
    def str_diff(s1, s2):
        fs1 = frozenset([repr(s1)])
        fs2 = frozenset([repr(s2)])
        return (fs1 - fs2, fs2 - fs1)

class RegularFile(File):
    def __init__(self, name, contents, encoding='utf-8'):
        super(RegularFile, self).__init__(name)
        self._contents = contents
        self._encoding = encoding

    def __sub__(self, other):
        c1, c2 = self._contents, other._contents
        raw_diff = [l for l in ndiff(c1.splitlines(), c2.splitlines())]
        plus = [l[2:] for l in raw_diff if l[0] == '-']
        minus = [l[2:] for l in raw_diff if l[0] == '+']
        return (File.str_diff(self._name, other._name), (plus, minus))

    def __repr__(self):
        return repr(self.__str__())

    def __str__(self):
        return """{0} : \"{1}\"""".format(self._name, self._contents)

class Directory(File):
    def __init__(self, name, reg_files=[], dirs=[], symlinks=[]):
        """
        :param name:
        :param reg_files:
        :param dirs:
        :param symlinks:
        """
        super(Directory, self).__init__(name)
        self._reg_files = frozenset(reg_files)
        self._dirs = frozenset(dirs)
        self._symlinks = frozenset(symlinks)

    def __sub__(self, other):
        return (File.str_diff(self._name, other._name),
                (self._reg_files - other._reg_files, other._reg_files - self._reg_files),
                (self._dirs - other._dirs, other._dirs - self._dirs),
                (self._symlinks - other._symlinks, other._reg_files - self._reg_files))

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return self._name + \
            '\nreg_files: ' + '\n'.join(self._reg_files) + \
            '\nsymlinks:  ' + '\n'.join(self._symlinks) + \
            '\nsub dirs:  ' + '\n'.join(self._dirs)

class SymLink(File):
    def __init__(self, name, target_path):
        super(SymLink, self).__init__(name)
        self._target_name = target_path

    def __sub__(self, other):
        return (File.str_diff(self._name, other._name),
                File.str_diff(self._target_name, other._target_name))


    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return '{0} -> {1}'.format(self._name, self._target_name)

def transpose_tuple(t):
    return tuple(zip(*t))

if __name__ == '__main__':
    f1 = RegularFile('f1', "a\nb")
    f2 = RegularFile('f1', "a\nb")
    d1 = Directory('d1', reg_files=[f1])
    d2 = Directory('d2', reg_files=[f2])
    print d1 - d2
    print File.is_zero(d1 - d2)
    print d1 == d2
