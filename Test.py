import boto3
s3 = boto3.resource('s3')
clientname=boto3.client('s3')
def lambda_handler(event, context):
    bucket = 'my-tf-test-bucket-dev'
    try:
        response = clientname.list_objects(
            Bucket=bucket,
            MaxKeys=5
        )
        for record in response['Contents']:
            key = record['Key']
            copy_source = {
                'Bucket': bucket,
                'Key': key
            }
            try:
                destbucket = s3.Bucket('my-tf-test-bucket-val')
                destbucket.copy(copy_source, key)
                print('{} transferred to destination bucket'.format(key))
            except Exception as e:
                print(e)
                print('Error getting object {} from bucket {}. '.format(key, bucket))
                raise e
    except Exception as e:
        print(e)
        raise e
