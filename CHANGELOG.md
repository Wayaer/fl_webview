## 0.3.1

* Optimize webView height calculation method

## 0.3.0

* Add two ways to get the content height in Android so that webView content can still be displayed
  when the content height is 0
* `onContentSizeChanged` add two callback sizes
* Add `useProgressGetContentSize`, When you use `FlAdaptHeightWevView` in Android it has to be set
  to true,

## 0.2.5

* Add does not support platform configuration

## 0.2.3

* Fix the caton problem in `ExtendedFlWebViewWithScrollView`

## 0.2.2

* Modify `onSizeChanged` to `onContentSizeChanged`
* Modify `FlAdaptWevView` to `FlAdaptHeightWevView`
* Modify rendering
* Add `onScrollChanged`
* Add `ExtendedFlWebViewWithScrollView()`,Improve the scrolling performance of WebView

## 0.1.0

* Fix bugs
* Update flutter version 2.5.0

## 0.0.9

* Get the height on Android when moving out `onPageFinished`

## 0.0.8

* Optimize WebView rendering
* fix the problem that no headers do not load URLs on Android

## 0.0.6

* Add initial `size` to `FlAdaptWevView`
* Fix bugs

## 0.0.3

* Support HTML text rendering
* Add `FlAdaptWevView` components

## 0.0.2

* Fix JS failed to call flutter on IOS

## 0.0.1

* Describe initial release.
