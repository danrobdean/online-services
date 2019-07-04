from __future__ import absolute_import
import apache_beam as beam

class getGcsFileList(beam.DoFn):

    def process(self, element):
        from apache_beam.io.gcp.gcsio import GcsIO

        prefix = element
        file_size_dict = GcsIO().list_prefix(prefix)
        file_list = file_size_dict.keys()

        for i in file_list:
            yield i
