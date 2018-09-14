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

#import <ShinobiCharts/ShinobiChart.h>
#import <ShinobiCharts/SChartCanvas.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <ShinobiCharts/SChartGLView.h>

@interface SChartGLView (Screenshot)
- (UIImage*)snapshot;
@end


#import <objc/runtime.h>

#define VIEWS_KEY "chartViews"
#define ADD_TO_GL_KEY "addToGL"

@interface ShinobiChart (Screenshot)
- (UIImage*)snapshot;
- (BOOL)addViewToSnapshot:(UIView *)view addToGLView:(BOOL)addToGL;
- (void)clearSnapshotViews;
@end

