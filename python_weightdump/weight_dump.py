def weight_dump(fname, arr):
    with open(fname, 'wb') as out_f:
        dump(arr, out_f)

def dump(data, out_f):
    if is_iterable(data):
        for d in data:
            dump(d, out_f)
    else:
        out = [
            (0x000000FF & data) >> 0,
            (0x0000FF00 & data) >> 8,
            (0x00FF0000 & data) >> 16,
            (0xFF000000 & data) >> 24,
        ]
        assert out_f.write(bytes(out)) == 4

def is_iterable(obj):
    try:
        _ = (e for e in obj)
        return True
    except TypeError:
        return False
