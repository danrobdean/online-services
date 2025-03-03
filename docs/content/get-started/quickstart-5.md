# Quickstart: 5. Connect a game client

The full connection flow goes something like this:

1. Talk to [PlayFab](https://api.playfab.com/docs/tutorials/landing-players/best-login) to get a token.
2. Exchange the PlayFab token for a PIT via the PlayFab Auth system we deployed.
3. Using PIT as an auth header, create a new party (or join an existing one) via the Party service.
4. Send a request to the Gateway to join the queue for a given game type.
5. Repeatedly check with the Gateway's Operations service whether you have a match for your party. When you do, you'll be given a Login Token and deployment name. You can use these to connect using the [normal SpatialOS flow](https://docs.improbable.io/reference/latest/shared/auth/integrate-authentication-platform-sdk#4-connecting-to-the-deployment).

A [sample client](http://github.com/spatialos/online-services/tree/master/services/csharp/SampleClient) is provided which demonstrates this flow up to and including obtaining a Login Token. Navigate there, and run:

```bash
dotnet run -- --google_project "[your Google project ID]" --playfab_title_id "[your PlayFab title ID]"
```

If everything has been set up correctly, you should see the script log in to PlayFab, obtain a PIT, create a party and then queue for a game. It won't get a match just yet though - we don't have any deployments that fit the Matcher's criteria.

> If you encounter errors at this step relating to authentication, go back to step 4 and ensure you configured the Kubernetes files with the correct values.

Start a deployment in the [usual way](https://docs.improbable.io/reference/latest/shared/deploy/deploy-cloud) - it doesn't matter what assembly or snapshot you use. You can leave the sample client running if you like. Once it's up, add the `match` and `ready` tags to the deployment.

`match` is the "game type" tag we're using for this example, while `ready` informs the matcher that the deployment is ready to accept players. You should quickly see the sample client script terminate, printing out the name of your deployment and a matching login token. You'll also see that the `ready` tag has been replaced by `in_use`. Congratulations; you followed the guide correctly. Everything's working.

![]({{assetRoot}}img/quickstart/demo.gif)

## Next steps

Next, you can customize the matcher logic to fit the needs of your game. </br>

There are two documents we recommend looking at next:

**Deployment pool** - You may want to deploy a deployment pool manager if you're making a session-based game like an arena shooter - see the [deployment pool documentation]({{urlRoot}}/content/configuration-examples/deployment-pool/overview) for more information.

**Local development** - The GDK for Unreal, the GDK for Unity and the Worker SDK have the option to run your game on your local development machine as if it were in the cloud - this is useful for faster development and testing iteration. You can do the same with Online Services. See the [local development]({{urlRoot}}/content/workflows/local.md) guide if you're planning to use local deployments to test Online Services.


<%(Nav hide="next")%>
<%(Nav hide="prev")%>

<br/>------------<br/>
_2019-07-16 Page added with limited editorial review_
[//]: # (TODO: https://improbableio.atlassian.net/browse/DOC-1135)
