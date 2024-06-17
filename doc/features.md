
- Event Listener
  - [Express Engine](#express-event-listeners)
  - [Media](#media-event-listeners)

---

# Event Listeners
## express event listeners

>
> In the [Zego Express Engine](https://pub.dev/packages/zego_express_engine), event callbacks are exclusive. 
> 
> This means that if any newly listener register to a event callback, the previously registered listener will become invalid.
>
> If you want to use both the [Zego Express Engine](https://pub.dev/packages/zego_express_engine) and the UIKit prebuilt series product together while also listening to events from Zego Express, you need to prevent the aforementioned event conflict issue. 
> To do this, please listen to the events thrown by ZegoUIKit. 

<details>
<summary>Example</summary>

>
> Here's how you can implement it:
>
> First, inherit the [ZegoUIKitExpressEventInterface](../zego_uikit/ZegoUIKitExpressEventInterface-class.html) and override the event listener you need, as shown below:
> ```dart
> class ExpressEvent extends ZegoUIKitExpressEventInterface
> {
>   @override
>   void onDebugError(
>       int errorCode,
>       String funcName,
>       String info,
>       ) {
>     /// your code
>   }
> }
> ```
> >
> Next, create an instance of your event listener class and register the event using `ZegoUIKit().registerExpressEvent`:
> ```dart
> final expressEvent = ExpressEvent();
> ZegoUIKit().registerExpressEvent(expressEvent);
> ```
>
> Finally, if you no longer want to listen to the events, you can unregister the event using `ZegoUIKit().unregisterExpressEvent`.
> ```dart
> ZegoUIKit().unregisterExpressEvent(expressEvent);
> ```

</details>

## media event listeners


>
> The media APIs is derived from the [Zego Express Engine](https://pub.dev/packages/zego_express_engine).
> 
> In the [Zego Express Engine](https://pub.dev/packages/zego_express_engine), event callbacks are exclusive.
> 
> This means that if any newly listener register to a event callback, the previously registered listener will become invalid.
>
> If you want to use both the [Zego Express Engine](https://pub.dev/packages/zego_express_engine) and the UIKit prebuilt series product together while also listening to events from Zego Express, you need to prevent the aforementioned event conflict issue.
> To do this, please listen to the events thrown by ZegoUIKit.

<details>
<summary>Example</summary>

>
> Here's how you can implement it:
>
> First, inherit the [ZegoUIKitMediaEventInterface](../zego_uikit/ZegoUIKitMediaEventInterface-class.html) and override the event listener you need, as shown below:
> ```dart
> class MediaEvent extends ZegoUIKitMediaEventInterface
> {
>   @override
>   void onMediaPlayerStateUpdate(
>       ZegoMediaPlayer mediaPlayer,
>       ZegoMediaPlayerState state,
>       int errorCode,) {
>     /// your code
>   }
> }
> ```
> >
> Next, create an instance of your event listener class and register the event using `ZegoUIKit().registerMediaEvent`:
> ```dart
> final mediaEvent = MediaEvent();
> ZegoUIKit().registerMediaEvent(mediaEvent);
> ```
>
> Finally, if you no longer want to listen to the events, you can unregister the event using `ZegoUIKit().unregisterMediaEvent`.
> ```dart
> ZegoUIKit().unregisterMediaEvent(mediaEvent);
> ```

</details>