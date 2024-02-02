import json
import boto3


def lambda_handler(event, context):
    # TODO implement
    
    dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    table = dynamodb.Table('db_visit_count')
    
    table.update_item(
        Key={
            'ref_id': 100
        },
        UpdateExpression='SET visits = visits + :val1',
        ExpressionAttributeValues={
            ':val1': 1
        }
    )
    
    response = table.get_item(
        Key={
            'ref_id': 100
        },
    )
    item = response['Item']
    return item