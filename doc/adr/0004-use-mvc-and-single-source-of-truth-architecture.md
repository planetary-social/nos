# 4. Use MVC and Single Source of Truth architecture

Date: 2023-01-31

Authors: Matt Lorentz, Martin Dutra

## Status

Accepted

## Context & Problem Statement

We need a common pattern for structuring our code that helps us write highly readable code at a high velocity while we quickly prototype this new app.

We are especially averse to boilerplate at this time since we are trying to build a functional app before showing it at Nostrica in 6 weeks.

These are roughly our requirements, quoted from [this post](https://web.archive.org/web/20230205014534/https://www.clientresourcesinc.com/2022/04/29/swiftui-choosing-an-application-architecture/)

It must be performant, no matter the application size.
It must be compatible with SwiftUI behavior and state management.
It should be concise, lightweight, adaptable, and flexible.
It encourages SwiftUI view composition.
It supports testing.

Here are a couple blog posts that resonated with our desire to find an architecture that takes full advantage of SwiftUI:
- https://web.archive.org/web/20230205014534/https://www.clientresourcesinc.com/2022/04/29/swiftui-choosing-an-application-architecture/
- https://matteomanferdini.com/swiftui-data-flow/

## Considered Options

### MVVM

Model-View-ViewModel was a common pattern for UIKit apps and many have applied it to SwiftUI as well. The View binds to the View Model which performs two way communication with the Model. This pattern was popular in UIKit apps to reduce the massive view controller problem.

**Pros**:
 
- Business logic and view interaction are easily testable.
- Model layer is relatively simple and focused on domain logic.
- Views are kept very simple

**Cons**:

- The View Model can end up being mostly boilerplate with SwiftUI, proxying binding from the view to other models/services.
- There is friction in View Model creation, instantiation, and ownership that discourages view composition.
- We can't use Core Data's @FetchRequest pattern to easily display updates to changes in the model layer. We need to find another system like NSFetchedResultsController + Combine.

### MVC

Model View Controller is an older pattern in which the View reads directly from the Model layer for display and all user interactions are sent to a Controller that manipulates the Model.

**Pros**:

- Core Data's @FetchRequest pattern fits well with this architecture, allowing the view to easily bind to the model.
- Creates a unidirectional data flow that separates display from mutation making both simpler to test.
- Business logic is easily testable

**Cons**:

- Difficult to reuse presentation and formatting logic
- Controllers can be largely boilerplate if business logic is well abstracted to other objects.

### Model View, or Apple's Single Source of Truth Architecture

In Apple's WWDC videos and example code they encourage binding SwiftUI Views directly to single sources of truth - authoritave sources for a given piece of data. Rather than having a single global state that is passed throughout the application, or intermediate objects proxying data from the model layer, they advocate to bind Views directly binding to the necessary data _as low in the view hierarchy as possible_. In this system everything that isn't a view should be a source of truth for data, leading some to refer to this architecture as Model View. The idea is that if views are kept small and simple then we don't need the additional complexity of systems like Clean or VIPER.

You can hear a lot of this is this [WWDC video](https://developer.apple.com/videos/play/wwdc2019/226/).

**Pros**

- Views are lightweight and composable
- Reduces state and boilerplate

**Cons**

- Reusing presentation logic can be difficult
- UI interactions are difficult to unit test

### React/Redux

React works much like Apple's single source of truth architecture, but instead of binding to individual sources of truth as low in the view hierarchy as possible, there is typically a single global state that is shared throughout the app.

**Pros**

- Unidirectional data flow
- Easier testing

**Cons**

- SwiftUI has performance problems with every view observing the same large state object.

### VIPER

VIPER is an application of Clean Architecture to iOS apps. The word VIPER is a backronym for View, Interactor, Presenter, Entity, and Routing. Clean Architecture divides an app’s logical structure into distinct layers of responsibility. (quoted from https://www.objc.io/issues/13-architecture/viper/)

**Pros**

- Components are highly isolated and very testable

**Cons**

- Lots of boilerplate and proxy objects
- Does not match SwiftUI's vision of binding directly to single sources of truth.

## Decision

Our preferred architecture will be Model View, where views interact directly with sources of truth. Where this architecture creates views that are too complex, or when we need to reuse presentation and interaction code we may fall back to MVC or MVVM.
