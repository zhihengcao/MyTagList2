//  ShinobiChart+Screenshot.h
//  Created by Stuart Grey on 22/02/2012.
//
//  Copyright 2013 Scott Logic
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ShinobiChart+Screenshot.h"

@implementation SChartGLView (Screenshot)

- (UIImage*)snapshot
{
    
    [EAGLContext setCurrentContext:[self getContext]];
    
    GLint backingWidth, backingHeight;
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    glBindRenderbuffer(GL_RENDERBUFFER, [self getColorRenderBuffer]);
    
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    glBindFramebuffer(GL_FRAMEBUFFER, [self getFramebuffer]);
    
    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints, heightInPoints;
    if (NULL != UIGraphicsBeginImageContextWithOptions) {
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        // Set the scale parameter to your OpenGL ES view's contentScaleFactor
        // so that you get a high-resolution snapshot when its value is greater than 1.0
        CGFloat scale = self.contentScaleFactor;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    else {
        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        widthInPoints = width;
        heightInPoints = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
    }
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    return image;
}

@end

@implementation ShinobiChart (Screenshot)

/**
 The addViewToSnapshot:addToGLView: method adds a view to be on top of the GLView in the Snapshot image which is
 returned in the snapshot method.
 @param view The UIView to be added to the snapshot image.
 @param addToGL A BOOL value defining whether the view passed in has been added to the GLView of the chart or the chart's view. If YES, the view will be added to the GLView. If NO, it wil be added to the chart's view.
 @returns A BOOL value representing whether the view passed in had been successfully added.
 */
- (BOOL)addViewToSnapshot:(UIView *)view addToGLView:(BOOL)addToGL {
    if(view){
        // Use associated references to simulate an ivar
        NSMutableArray *chartViews = objc_getAssociatedObject(self, VIEWS_KEY);
        if(!chartViews){
            chartViews = [[NSMutableArray new] autorelease];
        }
        NSMutableArray *addToGLViews = objc_getAssociatedObject(self, ADD_TO_GL_KEY);
        if(!addToGLViews){
            addToGLViews = [[NSMutableArray new] autorelease];
        }
        for(UIView *savedView in chartViews) {
            if([savedView isEqual:view]){
                return NO;
            }
        }
        [chartViews addObject:view];
        [addToGLViews addObject:[NSNumber numberWithBool:addToGL]];
        objc_setAssociatedObject(self, VIEWS_KEY, chartViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, ADD_TO_GL_KEY, addToGLViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    return NO;
}

/**
 The clearSnapshotViews method clears the arrays stored using associated reference.
 Call this when you no longer need the views you added via the addViewToSnapshot:addToGLView: method.
 */
-(void)clearSnapshotViews {
    objc_setAssociatedObject(self, VIEWS_KEY, nil, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, ADD_TO_GL_KEY, nil, OBJC_ASSOCIATION_RETAIN);
}

/**
 The snapshot method returns a UIImage of the chart with any views you added using the
 addViewToSnapshot:addToGLView: method to be drawn on top of the GLView.
 @returns A UIImage of your chart and any views you have added.
 */
- (UIImage*)snapshot {
    CGRect oldBounds;
    CGAffineTransform oldTransform;
    UIImage *image;
    CGRect glFrame = self.canvas.glView.frame;
    glFrame.origin.y = self.canvas.frame.origin.y;
    
    //Grab the GL screenshot
    UIImage *glImage = [self.canvas.glView snapshot];
    UIImageView *glImageView = [[[UIImageView alloc] initWithFrame:glFrame] autorelease];
    [glImageView setImage:glImage];
    
    //Grab the chart image (minus GL)
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(self.frame.size);
    }
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *chartImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Turn the chart image into a view and to create the composite
    UIImageView *chartImageView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
    [chartImageView setClipsToBounds:YES];
    [chartImageView setImage:chartImage];
    
    //Add our GL capture to our chart capture
    [chartImageView addSubview:glImageView];
    
    //Grab the annotations
    for (SChartAnnotation *ann in [self getAnnotations]) {
        if (ann.position == SChartAnnotationAboveData && [self annotationIsOnScreen:ann.frame]) {
            //if above gl, then add to top of glImageView (annotations under gl are already part of the chartImageView)
            
            CGRect annotationFrame = ann.frame;
			UIImage *editedAnnotationImage; // = image;
            
            //record annotations current bounds and transform
            oldBounds = ann.bounds;
            oldTransform = ann.transform;
            
            image = [self setUpImageForView:ann];
            
            // Reset frame origin and into account the axis lines
            glFrame.origin = CGPointMake([self.yAxis.style.lineWidth floatValue],
                                         [self.yAxis.style.lineWidth floatValue]);
            glFrame.size = CGSizeMake(glFrame.size.width - (2 * [self.yAxis.style.lineWidth floatValue]),
                                      glFrame.size.height - (2 * [self.yAxis.style.lineWidth floatValue]));
            
            CGRect cropFrame = CGRectMake(0, 0, annotationFrame.size.width, annotationFrame.size.height);
            
            // If annotation frame is overlapping left or right side of chart
            if(CGRectGetMaxX(annotationFrame) > CGRectGetMaxX(glFrame)){
                annotationFrame = CGRectMake(annotationFrame.origin.x,
                                             annotationFrame.origin.y,
                                             CGRectGetMaxX(glFrame) - annotationFrame.origin.x,
                                             annotationFrame.size.height);
                cropFrame.size = CGSizeMake(annotationFrame.size.width, annotationFrame.size.height);
            }else if(annotationFrame.origin.x < glFrame.origin.x){
                cropFrame = CGRectMake(glFrame.origin.x - annotationFrame.origin.x,
                                       cropFrame.origin.y,
                                       CGRectGetMaxX(annotationFrame) - glFrame.origin.x,
                                       cropFrame.size.height);
                annotationFrame = CGRectMake(glFrame.origin.x,
                                             annotationFrame.origin.y,
                                             CGRectGetMaxX(annotationFrame) - glFrame.origin.x,
                                             annotationFrame.size.height);
            }
            
            // If annotation frame is overlapping top or bottom side of chart
            if(CGRectGetMaxY(annotationFrame) > CGRectGetMaxY(glFrame)){
                cropFrame.size = CGSizeMake(cropFrame.size.width, CGRectGetMaxY(glFrame) - annotationFrame.origin.y);
                annotationFrame = CGRectMake(annotationFrame.origin.x,
                                             annotationFrame.origin.y,
                                             annotationFrame.size.width,
                                             CGRectGetMaxY(glFrame) - annotationFrame.origin.y);
            }else if(annotationFrame.origin.y < glFrame.origin.y){
                cropFrame = CGRectMake(cropFrame.origin.x,
                                       glFrame.origin.y - annotationFrame.origin.y,
                                       cropFrame.size.width,
                                       CGRectGetMaxY(annotationFrame) - glFrame.origin.y);
                annotationFrame = CGRectMake(annotationFrame.origin.x,
                                             glFrame.origin.y,
                                             annotationFrame.size.width,
                                             CGRectGetMaxY(annotationFrame) - glFrame.origin.y);
            }
            
            // Crop image if it needs cropping
            if(cropFrame.size.height != ann.frame.size.height || cropFrame.size.width != ann.frame.size.width){
                CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropFrame);
                editedAnnotationImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
                image = editedAnnotationImage;
            }
            [glImageView addSubview:[self imageViewForView:ann withFrame:annotationFrame withImage:image withBounds:oldBounds withTransform:oldTransform]];
        }
    }
    
    NSMutableArray *chartViews = objc_getAssociatedObject(self, VIEWS_KEY);
    NSMutableArray *addToGLViews = objc_getAssociatedObject(self, ADD_TO_GL_KEY);
    
    // Loop through chartViews array
    for(int i = 0; i < chartViews.count; i++) {
        UIView *view = [chartViews objectAtIndex:i];
        
        //record view's current bounds and transform
        oldBounds = view.bounds;
        oldTransform = view.transform;
        
        image = [self setUpImageForView:view];
        
        // Adds view to either GLView or the Chart's View
        if([[addToGLViews objectAtIndex:i] boolValue]) {
            [glImageView addSubview:[self imageViewForView:view withFrame:view.frame withImage:image withBounds:oldBounds withTransform:oldTransform]];
        } else {
            [chartImageView addSubview:[self imageViewForView:view withFrame:view.frame withImage:image withBounds:oldBounds withTransform:oldTransform]];
        }
    }
    
    //Turn our composite into a single image

    UIGraphicsBeginImageContextWithOptions(chartImageView.bounds.size, NO, [UIScreen mainScreen].scale);
    [chartImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *completeChartImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return completeChartImage;
}

#pragma Private Methods

/**
 This private method returns a UIImage of the view passed in.
 @param view The UIView to take an image of.
 @returns A UIImage of the view passed in.
 */
-(UIImage*)setUpImageForView:(UIView*)view{
    /* Certain annotations have transforms applied to them - see updateViewWithCanvas: of SChartAnnotationZooming. Due to this we have to ensure that the bounds are correct before starting (and that we have reset the transform).*/
    //get correct bounds of annotation
    CGRect correctBounds = view.frame;
    correctBounds.origin = CGPointZero;
    CGContextRef context;
    
    //set correct bounds and identity transform
    view.bounds = correctBounds;
    view.transform = CGAffineTransformIdentity;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [UIScreen mainScreen].scale);
    } else {
        UIGraphicsBeginImageContext(view.frame.size);
    }
    context = UIGraphicsGetCurrentContext();
    
    [view.layer renderInContext:context];
    
    UIImage *setUpImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return setUpImage;
}

/**
 This private method returns an UIImageView of the image passed in. It also resets the passed in view's bounds & transform values.
 @param view The UIView to have its bounds & transform values reset.
 @param frame The CGRect value to set as the UIImageView's frame.
 @param image The UIImage value to set as the UIImageView's image.
 @param oldBounds A CGRect of the passed in view's old bounds value.
 @param oldTransform A CGAffineTransform of the passed in view's old trasnform value.
 @returns A UIImageView of the view passed in.
 */
-(UIImageView*)imageViewForView:(UIView*)view withFrame:(CGRect)frame withImage:(UIImage*)image withBounds:(CGRect)oldBounds withTransform:(CGAffineTransform)oldTransform {
    UIImageView *imageView = [[[UIImageView alloc] initWithFrame:frame] autorelease];
    [imageView setImage:image];
    
    //set bounds and transform back
    view.bounds = oldBounds;
    view.transform = oldTransform;
    
    return imageView;
}

/**
 This private method checks whether the frame of an SChartAnnotation is on screen.
 @param frame A CGRect of an SChartAnnotation's frame to check whether it is on screen.
 @returns A BOOL value representing whether the frame passed in is on screen.
 */
-(BOOL)annotationIsOnScreen:(CGRect)frame {
    if(CGRectGetMaxX(frame) >= 0 && frame.origin.x <= self.canvas.glView.frame.size.width){
        if(CGRectGetMaxY(frame) >= 0 && frame.origin.y <= self.canvas.glView.frame.size.height){
            return YES;
        }
    }
    return NO;
}

@end
