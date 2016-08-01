import os
import shutil
import errno


def default(args):
    assert (not hasattr(args, 'as_typed')) or hasattr(args, 'replicate')
    assert args.source and args.destination

def inverse(args):
    assert not hasattr(args, 'as_typed') and not hasattr(args, 'replicate')
    assert hasattr(args, 'source') and not hasattr(args, 'destination')

    src = os.path.abspath(args.source)
    if not os.path.islink(src):
        raise ValueError('cannot invert source that is not a symlink')
    dst = os.path.abspath(os.readlink(src))
    src_base = os.path.basename(src)
    dst_base = os.path.basename(dst)
    if src_base != dst_base:
        raise ValueError('Link name different from target. Was this linked properly?')

    os.remove(src)
    src_par = os.path.dirname(src)
    shutil.move(dst, src_par)

    remove_empty_dirs(os.path.dirname(dst))

def remove_empty_dirs(dir_path):
    """
    Deletes empty directory chain as far up as possible.
    :param dst_dir: path to directory
    :return: void
    """
    try:
        os.rmdir(dir_path)
        parent = os.path.dirname(dir_path)
        if os.path.isdir(parent):
            remove_empty_dirs(parent)
    except OSError as e:
        if e.errno != errno.ENOTEMPTY:
            raise



if __name__ == '__main__':
    args.func(args)
