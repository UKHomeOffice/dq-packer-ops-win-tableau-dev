import boto3
import os
import logging

logging.basicConfig(
    filename='sqlworkbench-config-pull-logs.txt',
    format='%(asctime)s %(message)s',
    datefmt='%d/%m/%Y %H:%M:%S',
    level=logging.INFO
)

class S3Copier:
    def __init__(self, input_location, output_location):
        self.input_location = input_location
        self.input_bucket = input_location.split('/')[0]
        self.input_prefix = '/'.join(input_location.split('/')[1:])
        self.output_location = output_location
        self.s3_client = boto3.resource('s3')

    def _create_dir_if_not_exists(self, path):
        """Create local directory if it doesn't exist"""
        if not os.path.isdir(path):
            logging.info('Directory {0} does not exist. Creating'.format(path))
            os.makedirs(path)

    def _get_file_names(self):
        """Return a list of files in the configured s3 input location"""
        return self.s3_client.Bucket(self.input_bucket).objects.filter(Prefix=self.input_prefix)

    def copy(self):
        """Copy all files from the configured s3 input location to local output location"""
        try:
            self._create_dir_if_not_exists(self.output_location)
            for file_name in self._get_file_names():
                f_name = file_name.key.split('/')[-1]
                self.s3_client \
                    .Bucket(self.input_bucket) \
                    .download_file(file_name.key, '{0}/{1}' \
                    .format(self.output_location, f_name))
                logging.info('Successfully pulled {0}'.format(f_name))
        except Exception as e:
            logging.info('Failed to pull files')
            logging.info(e)

if __name__ == '__main__':
    logging.info('Starting')
    output_dir = 'C:/Users/Public/.sqlworkbench'
    input_dir = os.environ.get('S3_OPS_CONFIG_BUCKET')
    S3Copier(input_dir, output_dir).copy()
    logging.info('Task complete')
