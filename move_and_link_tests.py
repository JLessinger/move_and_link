import os
import errno
import shutil
import unittest


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def touch(f_path, contents):
    d = os.path.dirname(f_path)
    if not os.path.isdir(d):
        mkdir_p(d)
    with open(f_path, 'w') as f:
        if contents:
            f.write(contents)

class MainTests(unittest.TestCase):
    rel_test_root = os.path.join(os.getcwd(), 'testdir')

    def setUp(self):
        if os.path.isdir(MainTests.rel_test_root):
            shutil.rmtree(MainTests.rel_test_root)
        MainTests.mkdir_p_for_test('disk1')
        MainTests.mkdir_p_for_test('disk2')

    def tearDown(self):
        shutil.rmtree(MainTests.rel_test_root)

    @staticmethod
    def mkdir_p_for_test(d):
        mkdir_p(os.path.join(MainTests.rel_test_root, d))

    @staticmethod
    def touch_for_test(f_path, contents=None):
        touch(os.path.join(MainTests.rel_test_root, f_path), contents)

    def test_simple(self):
        MainTests.touch_for_test('disk1/dir/f')
        MainTests.mkdir_p_for_test('disk2/dir')
        self.assertTrue(False)

if __name__ == '__main__':
    unittest.main()