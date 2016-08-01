import os
import shutil
import errno


def default(args):
    assert (not args.as_typed) or args.replicate
    assert args.source and args.destination

    src = args.source
    if os.path.islink(src):
        raise ValueError('move-and-link not defined if source is already a link')
    if not (os.path.isfile(src) or os.path.isdir(src)):
        raise ValueError('no such file or directory: {0}'.format(src))

    dst = args.destination

    if args.replicate:
        if args.as_typed:
            pass #TODO
        else:
            pass #TODO

    mkdir_p(dst)
    shutil.move(src, dst)

    item = os.path.basename(src)
    dst_path = os.path.join(dst, item)
    os.symlink(os.path.abspath(dst_path), src)

def inverse(args):
    assert not args.as_typed and not args.replicate
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

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

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
    args = lambda l: 1
    args.source = 'f'
    args.as_typed = False
    args.replicate = False
    #inverse(args)
    args.destination = 'some/dir'
    default(args)