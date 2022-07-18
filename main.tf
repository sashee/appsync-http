provider "aws" {
}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_iam_role" "appsync" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "appsync_push_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "appsync_logs" {
  role   = aws_iam_role.appsync.id
  policy = data.aws_iam_policy_document.appsync_push_logs.json
}

resource "aws_appsync_graphql_api" "appsync" {
  name                = "appsync_test"
  schema              = file("schema.graphql")
  authentication_type = "AWS_IAM"
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync.arn
    field_log_level          = "ALL"
  }
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/appsync/apis/${aws_appsync_graphql_api.appsync.id}"
  retention_in_days = 14
}

resource "aws_appsync_datasource" "xkcd" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "xkcd"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "HTTP"
	http_config {
		endpoint = "https://xkcd.com"
	}
}

resource "aws_appsync_datasource" "webhook" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "webhook"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "HTTP"
	http_config {
		endpoint = "https://webhook.site"
	}
}

resource "aws_appsync_datasource" "webhook_signed" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "webhook_signed"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "HTTP"
	http_config {
		endpoint = "https://webhook.site"
		authorization_config {
			authorization_type = "AWS_IAM"
			aws_iam_config {
				signing_region = "us-west-2"
				signing_service_name = "abc"
			}
		}
	}
}

resource "aws_appsync_datasource" "reddit" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "reddit"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "HTTP"
	http_config {
		endpoint = "https://www.reddit.com/"
	}
}

# resolvers
resource "aws_appsync_resolver" "Query_webhook" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "webhook"
  data_source = aws_appsync_datasource.webhook.name
	request_template = <<EOF
{
	"version": "2018-05-29",
	"method": "GET",
	"params": {
		"query": {
			"queryvalue": "testvalue"
		},
		"headers": {
			"Content-Type" : "application/json",
			"testheader" : "value"
		},
		"body": "example body"
	},
	"resourcePath": "/$ctx.args.id"
}
EOF

	response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

resource "aws_appsync_resolver" "Query_webhook_signed" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "webhook_signed"
  data_source = aws_appsync_datasource.webhook_signed.name
	request_template = <<EOF
{
	"version": "2018-05-29",
	"method": "GET",
	"params": {
		"query": {
			"queryvalue": "testvalue"
		},
		"headers": {
			"Content-Type" : "application/json",
			"testheader" : "value"
		},
		"body": "example body"
	},
	"resourcePath": "/$ctx.args.id"
}
EOF

	response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

resource "aws_appsync_resolver" "Query_latestXkcd" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "latestXkcd"
  data_source = aws_appsync_datasource.xkcd.name
	request_template = <<EOF
{
	"version": "2018-05-29",
	"method": "GET",
	"params": {
		"query": {},
		"headers": {
			"Content-Type" : "application/json"
		},
	},
	"resourcePath": "/info.0.json"
}
EOF

	response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
#if ($ctx.result.statusCode < 200 || $ctx.result.statusCode >= 300)
	$util.error($ctx.result.body, "StatusCode$ctx.result.statusCode")
#end
$ctx.result.body
EOF
}

resource "aws_appsync_resolver" "Query_topPosts" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "topPosts"
  data_source = aws_appsync_datasource.reddit.name
	request_template = <<EOF
{
	"version": "2018-05-29",
	"method": "GET",
	"params": {
		"query": {"limit": "3"},
		"headers": {
			"Content-Type" : "application/json"
		},
	},
	"resourcePath": "/r/$ctx.args.topic/top.json"
}
EOF

	response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
#if ($ctx.result.statusCode < 200 || $ctx.result.statusCode >= 300)
	$util.error($ctx.result.body, "StatusCode$ctx.result.statusCode")
#end
#set($result = [])
#foreach($item in $util.parseJson($ctx.result.body).data.children)
	$util.qr($result.add($item.data))
#end
$util.toJson($result)
EOF
}

