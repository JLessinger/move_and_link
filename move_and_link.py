import os

import shutil


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


if __name__ == '__main__':
    args.func(args)