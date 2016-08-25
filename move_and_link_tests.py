import os
import errno
import shutil
import unittest


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def create_file(f_path, contents):
    d = os.path.dirname(f_path)
    if not os.path.isdir(d):
        mkdir_p(d)
    with open(f_path, 'w') as f:
        if contents:
            f.write(contents)

class MainTests(unittest.TestCase):
    test_root = os.path.join(os.getcwd(), 'testdir')

    def setUp(self):
        if os.path.isdir(MainTests.test_root):
            shutil.rmtree(MainTests.test_root)
        MainTests.mkdir_p_for_test('disk1')
        MainTests.mkdir_p_for_test('disk2')

    def tearDown(self):
        pass
        #shutil.rmtree(MainTests.test_root)

    @staticmethod
    def mkdir_p_for_test(d):
        mkdir_p(os.path.join(MainTests.test_root, d))

    @staticmethod
    def create_file_for_test(f_path, contents=None):
        create_file(os.path.join(MainTests.test_root, f_path), contents)

    def test_simple(self):
        MainTests.create_file_for_test('disk1/dir/f')
        MainTests.mkdir_p_for_test('disk2/dir')

    def run_test(self, expected_src_diff, expected_dest_diff):
        src_root = os.path.join(MainTests.test_root, 'disk1')
        dest_root = os.path.join(MainTests.test_root, 'disk2')
        before_root = os.path.join(MainTests.test_root, 'before')
        after_root = os.path.join(MainTests.test_root, 'after')
        shutil.copytree(src_root, before_root, symlinks=True)
        shutil.copytree(dest_root, before_root, symlinks=True)
        shutil.copytree(src_root, after_root, symlinks=True)
        shutil.copytree(dest_root, after_root, symlinks=True)
        src_before = os.path.join(before_root, 'disk1')
        src_after = os.path.join(after_root, 'disk1')
        src_before = os.path.join(before_root, 'disk2')
        src_after = os.path.join(after_root, 'disk2')


if __name__ == '__main__':
    unittest.main()