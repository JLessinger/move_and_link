def default(args):
    assert (not args.as_typed) or (args.replicate)

def inverse(args):
    assert not (args.as_typed or args.replicate)

if __name__ == '__main__':
    # produce parsed argument object called args
    # func should be either "default" or "inverse" depending on which subcommand is given
    args.func(args)