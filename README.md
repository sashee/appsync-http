# Example code for AppSync HTTP data source

## Deploy

* ```terraform init```
* ```terraform apply```

## Usage

### Latest XKCD

Sends a request to https://xkcd.com/info.0.json

```graphql
query MyQuery {
  latestXkcd
}
```

```json
{
  "data": {
    "latestXkcd": "{\"month\":\"7\",\"num\":2645,\"link\":\"\",\"year\":\"2022\",\"news\":\"\",\"safe_title\":\"The Best Camera\",\"transcript\":\"\",\"alt\":\"The best camera is the one at L2.\",\"img\":\"https://imgs.xkcd.com/comics/the_best_camera.png\",\"title\":\"The Best Camera\",\"day\":\"13\"}"
  }
}
```

### Reddit posts

Sends a request to ```https://www.reddit.com/r/<topic>/top.json?limit=3```

```graphql
query MyQuery {
  topPosts(topic: "programming") {
    author
    downs
    title
    ups
    url
  }
}
```

```json
{
  "data": {
    "topPosts": [
      {
        "author": "kisamoto",
        "downs": 0,
        "title": "Poll: Do you expect/want to see salary information in a job ad?",
        "ups": 1707,
        "url": "https://news.ycombinator.com/item?id=32095140"
      },
      {
        "author": "dawgyo",
        "downs": 0,
        "title": "I built a Chrome extension to directly save jobs from LinkedIn and Indeed to Google Sheets so you can easily organize and keep track of your job applications",
        "ups": 168,
        "url": "https://chrome.google.com/webstore/detail/resumary-oneclick-save-jo/mkjedhephckpdnpadogmilejdbgbbdfm"
      },
      {
        "author": "agbell",
        "downs": 0,
        "title": "The Slow March of Progress in Programming Language Tooling",
        "ups": 130,
        "url": "https://earthly.dev/blog/programming-language-improvements/"
      }
    ]
  }
}
```

### Debugging with webhook.site

* Go to [https://webhook.site/](https://webhook.site/) and get a token (it's the UUID in the unique URL: ```https://webhook.site/<token>```)

```graphql
query MyQuery {
  webhook(id: "317ef0fb-b10f-4bf0-ba72-87fc972d63a5")
}
```

* Inspect the result

![image](https://user-images.githubusercontent.com/82075/179212448-e3bc7b31-c169-43d9-9ad4-0a86ad6c6d47.png)

#### AWS signed requests

```graphql
query MyQuery {
  webhook_signed(id: "317ef0fb-b10f-4bf0-ba72-87fc972d63a5")
}
```

![image](https://user-images.githubusercontent.com/82075/179212534-356a2624-4b3a-49ee-bb99-f36f764dec44.png)

## Cleanup

* ```terraform destroy```
