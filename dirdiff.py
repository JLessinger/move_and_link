import collections
from difflib import ndiff
from utility.objects import SmartHashable


class File(SmartHashable):
    def __init__(self, name):
        super(File, self).__init__()
        self._name = name
        
    def is_zero(self):
        return self._name == ''

    @staticmethod
    def str_diff(s1, s2):
        if s1 == s2:
            return '', ''
        else:
            return s1, s2

class RegularFile(File):
    def __init__(self, name, contents, encoding='utf-8'):
        super(RegularFile, self).__init__(name)
        self._contents = contents
        self._encoding = encoding
        
    def is_zero(self):
        return super(RegularFile, self).is_zero() and \
               self._contents == ''

    def __sub__(self, other):
        c1, c2 = self._contents, other._contents
        raw_diff = [l for l in ndiff(c1.splitlines(), c2.splitlines())]
        plus_contents = [l[2:] for l in raw_diff if l[0] == '-']
        minus_contents = [l[2:] for l in raw_diff if l[0] == '+']
        name_diff = File.str_diff(self._name, other._name)
        plus_file = RegularFile(name_diff[0], plus_contents)
        minus_file = RegularFile(name_diff[1], minus_contents)
        return plus_file, minus_file

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
        
    def is_zero(self):
        return super(Directory, self).is_zero() and \
               all([f.is_zero() for f in self._reg_files]) and \
               all([d.is_zero for d in self._dirs]) and \
               all([l.is_zero for l in self._symlinks])
        
    def __sub__(self, other):
        name_diffs = File.str_diff(self._name, other._name)
        reg_file_diffs, subdir_diffs, link_diffs =         \
                (self._reg_files - other._reg_files, other._reg_files - self._reg_files), \
                (self._dirs - other._dirs, other._dirs - self._dirs), \
                (self._symlinks - other._symlinks, other._symlinks - self._symlinks)
        plus_dir = Directory(name_diffs[0], reg_file_diffs[0], subdir_diffs[0], link_diffs[0])
        minus_dir = Directory(name_diffs[1], reg_file_diffs[1], subdir_diffs[1], link_diffs[1])
        return plus_dir, minus_dir

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return 'dir name: \"' + self._name + '\"'\
            '\nreg_files: ' + '\n'.join([str(f) for f in self._reg_files]) + \
            '\nsymlinks:  ' + '\n'.join([str(l) for l in self._symlinks]) + \
            '\nsub dirs:  ' + '\n'.join([str(d) for d in self._dirs])

class SymLink(File):
    def __init__(self, name, target_path):
        super(SymLink, self).__init__(name)
        self._target_name = target_path
        
    def is_zero(self):
        return super(SymLink, self).is_zero() and \
               self._target_name == ''

    def __sub__(self, other):
        name_diffs = File.str_diff(self._name, other._name),
        target_diffs = File.str_diff(self._target_name, other._target_name)
        return SymLink(name_diffs[0], target_diffs[0]), \
               SymLink(name_diffs[1], target_diffs[1])
    

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return '{0} -> {1}'.format(self._name, self._target_name)

def transpose_tuple(t):
    return tuple(zip(*t))

if __name__ == '__main__':
    f1 = RegularFile('f1', "a\nb")
    f2 = RegularFile('f2', "a\nb")
    d1 = Directory('d1', reg_files=[f1])
    d2 = Directory('d1', reg_files=[f2])
    diff = d1 - d2
    print diff[0]
    print diff[1]
    print [diff_part.is_zero() for diff_part in diff]
    print d1 == d2
    expected_diff = (Directory('', [f1], [], []), Directory('', [f2], [], []))
    print diff == expected_diff