import dill
import codecs
import pandas as pd

def load_dill_string(s):  # pragma: no cover
    return dill.loads(codecs.decode(s.encode(), "base64"))

def get_dill_string(obj):  # pragma: no cover
    return codecs.encode(dill.dumps(obj, protocol=5, recurse=True), "base64").decode()

def read_pickle_file(file):
    pickle_data = pd.read_pickle(file)
    return pickle_data
