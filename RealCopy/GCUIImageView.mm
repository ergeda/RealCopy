//
//  GCUIImageView.mm
//  RealCopy
//
//  Created by Yaming Xu on 2017/09/10.
//  Copyright © 2017 Yaming Xu. All rights reserved.
//

#import "GCUIImageView.h"
#import "ForegroundSetterButton.h"
#import "BackgroundSetterButton.h"
#import "CameraShutterButton.h"
#import "opencv2/opencv.hpp"
#import "SVProgressHUD.h"
#include "graph.h"


// Category - UIImageScale
@interface UIImage(UIImageScale)

-(UIImage*)scaleToSize:(CGSize)size;
-(UIImage*)getSubImage:(CGRect)rect;

@end

@implementation UIImage(UIImageScale)

-(UIImage*)getSubImage:(CGRect)rect
{
    @autoreleasepool{
        CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
        CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
        
        UIGraphicsBeginImageContext(smallBounds.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawImage(context, smallBounds, subImageRef);
        UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
        UIGraphicsEndImageContext();
        CGImageRelease(subImageRef);
        
        return smallImage;
    }
}

-(UIImage *)scaleToSize:(CGSize)targetSize
{
    @autoreleasepool{
        UIImage *sourceImage = self;
        UIImage *newImage = nil;
        
        CGSize imageSize = sourceImage.size;
        CGFloat width = imageSize.width;
        CGFloat height = imageSize.height;
        
        CGFloat targetWidth = targetSize.width;
        CGFloat targetHeight = targetSize.height;
        
        CGFloat scaleFactor = 0.0;
        CGFloat scaledWidth = targetWidth;
        CGFloat scaledHeight = targetHeight;
        
        CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
        
        if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
            CGFloat widthFactor = targetWidth / width;
            CGFloat heightFactor = targetHeight / height;
            
            if (widthFactor < heightFactor)
                scaleFactor = widthFactor;
            else
                scaleFactor = heightFactor;
            
            scaledWidth  = width * scaleFactor;
            scaledHeight = height * scaleFactor;
            
            // center the image
            if (widthFactor < heightFactor) {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            } else if (widthFactor > heightFactor) {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
        
        // this is actually the interesting part:
        UIGraphicsBeginImageContext(targetSize);
        
        CGRect thumbnailRect = CGRectZero;
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width  = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        
        [sourceImage drawInRect:thumbnailRect];
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if(newImage == nil) NSLog(@"could not scale image");
        return newImage ;
    }
}

@end


// graph
typedef Graph<int,int,int> GraphType;
GraphType *myGraph;

CvPoint prev_pt;
// images
cv::Mat inputImg;
cv::Mat showEdgesImg;
cv::Mat binPerPixelImg;
cv::Mat segMask;

// mask
cv::Mat fgScribbleMask;
cv::Mat bgScribbleMask;

// user clicked mouse buttons flags
int numUsedBins;
float varianceSquared;
int scribbleRadius;

// default arguments
float bha_slope;
int numBinsPerChannel;

float INT32_CONST;
float HARD_CONSTRAINT_CONST;

int NEIGHBORHOOD;

typedef NS_ENUM(NSInteger, BarButtonTag) {
    ForegroundSetterTag,
    BackgroundSetterTag,
    DoneSetterTag,
    ExitTag
};

@interface GCUIImageView()
{
    int currentMode;// indicate foreground or background, foreground as default
    CvScalar paintColor[2];
    
    int SCALE;
    
    IplImage* img;
    CvPoint prev_pt;
}

@property (nonatomic, strong) ForegroundSetterButton *foregroundSetterButton;
@property (nonatomic, strong) BackgroundSetterButton *backgroundSetterButton;
@property (nonatomic, strong) CameraShutterButton *doneSetterButton;
@property (nonatomic, strong) CameraShutterButton *exitButton;

@end

@implementation GCUIImageView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(id)init {
    if (self = [super init]) {
        //Create color picker button
        _foregroundSetterButton = [ForegroundSetterButton new];
        _backgroundSetterButton = [BackgroundSetterButton new];
        _doneSetterButton = [CameraShutterButton new];
        _exitButton = [CameraShutterButton new];
        
        // enable user interaction on UIImageView
        self.userInteractionEnabled = YES;
        
        // user clicked mouse buttons flags
        numUsedBins = 0;
        varianceSquared = 0;
        scribbleRadius = 10;

        // default arguments
        bha_slope = 0.1f;
        numBinsPerChannel = 64;
        
        INT32_CONST = 1000;
        HARD_CONSTRAINT_CONST = 1000;
        
        NEIGHBORHOOD = 1;
        
        currentMode = 0; // indicate foreground or background, foreground as default
        paintColor[0] = CV_RGB(0, 0, 255);
        paintColor[1] = CV_RGB(255, 0, 0);
        
        prev_pt = {-1, -1};
        SCALE = 1;
    }
    return self;
}

-(void)initColorPicker {
    if (_foregroundSetterButton) {
        //Button Visual attribution
        _foregroundSetterButton.frame = (CGRect){0, 0, static_cast<CGFloat>(self.bounds.size.width * 0.18),
            static_cast<CGFloat>(self.bounds.size.width * 0.18)};
        _foregroundSetterButton.center = CGPointMake(self.frame.size.width * 0.2, self.frame.size.height*0.875);
        _foregroundSetterButton.tag = ForegroundSetterTag;
        _foregroundSetterButton.backgroundColor = [UIColor clearColor];
        
        //Button target
        [_foregroundSetterButton addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_foregroundSetterButton];
    }
    
    if (_backgroundSetterButton) {
        //Button Visual attribution
        _backgroundSetterButton.frame = (CGRect){0, 0, static_cast<CGFloat>(self.bounds.size.width * 0.18),
            static_cast<CGFloat>(self.bounds.size.width * 0.18)};
        _backgroundSetterButton.center = CGPointMake(self.frame.size.width * 0.4, self.frame.size.height*0.875);
        _backgroundSetterButton.tag = BackgroundSetterTag;
        _backgroundSetterButton.backgroundColor = [UIColor clearColor];
        
        //Button target
        [_backgroundSetterButton addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_backgroundSetterButton];
    }

    if (_doneSetterButton) {
        //Button Visual attribution
        _doneSetterButton.frame = (CGRect){0, 0, static_cast<CGFloat>(self.bounds.size.width * 0.18),
            static_cast<CGFloat>(self.bounds.size.width * 0.18)};
        _doneSetterButton.center = CGPointMake(self.frame.size.width * 0.6, self.frame.size.height*0.875);
        _doneSetterButton.tag = DoneSetterTag;
        _doneSetterButton.backgroundColor = [UIColor clearColor];
        
        //Button target
        [_doneSetterButton addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_doneSetterButton];
    }
    
    if (_exitButton) {
        //Button Visual attribution
        _exitButton.frame = (CGRect){0, 0, static_cast<CGFloat>(self.bounds.size.width * 0.18),
            static_cast<CGFloat>(self.bounds.size.width * 0.18)};
        _exitButton.center = CGPointMake(self.frame.size.width * 0.8, self.frame.size.height*0.875);
        _exitButton.tag = ExitTag;
        _exitButton.backgroundColor = [UIColor clearColor];
        
        //Button target
        [_exitButton addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_exitButton];
    }
}

-(void)setup {
    [self initColorPicker];

    // setup images
    if (self.image) {
        self.image = [self.image scaleToSize:[self frameForImage:self.image inImageViewAspectFit:self].size];
        img = [self CreateIplImageFromUIImage:self.image];
        inputImg = [self cvMatFromUIImage:self.image];
        cv::cvtColor(inputImg, inputImg, CV_RGBA2RGB);
        setupImages();
    }
}


#pragma mark - User Interaction

-(void)inputManager:(id)sender {
    //If sender does not inherit from 'UIButton', return
    if (![sender isKindOfClass:[UIButton class]]) return;
    
    //Input manager switch
    switch ([(UIButton *)sender tag]) {
        case ForegroundSetterTag:  currentMode = 0;  return;
        case BackgroundSetterTag:  currentMode = 1;  return;
        case DoneSetterTag:  [self onTapDoneSetter];  return;
        case ExitTag:  [self onTapExit];  return;
    }
}

-(void)onTapExit {
    if (self.delegate) {
        [self.delegate switchToCameraViewAndSaveImage:self.image];
    }
}

-(void)onTapDoneSetter {
    [SVProgressHUD show];
    
    for(int i=0; i<inputImg.rows; i++)
    {
        for(int j=0; j<inputImg.cols; j++)
        {
            // this is the node id for the current pixel
            GraphType::node_id currNodeId = i * inputImg.cols + j;
            
            // add hard constraints based on scribbles
            if (fgScribbleMask.at<uchar>(i,j) == 255)
                myGraph->add_tweights(currNodeId,(int)ceil(INT32_CONST * HARD_CONSTRAINT_CONST + 0.5), 0);
            else if (bgScribbleMask.at<uchar>(i,j) == 255)
                myGraph->add_tweights(currNodeId,0,(int)ceil(INT32_CONST * HARD_CONSTRAINT_CONST + 0.5));
        }
    }
    
    myGraph -> maxflow();
    
    // copy the segmentation results on to the result images
    for (int i = 0; i<inputImg.rows * inputImg.cols; i++)
    {
        // if it is foreground - color blue
        if (myGraph->what_segment((GraphType::node_id)i ) == GraphType::SOURCE)
        {
            segMask.at<uchar>(i/inputImg.cols, i%inputImg.cols) = 0;
        }
        // if it is background - color red
        else
        {
            segMask.at<uchar>(i/inputImg.cols, i%inputImg.cols) = 255;
        }
    }
    self.image = [self maskImage:self.image withMask:[self UIImageFromCVMat:segMask]];
    
    [SVProgressHUD dismiss];
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    //CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(( CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (IplImage*) CreateIplImageFromUIImage:(UIImage*)image
{
    CGImageRef imageRef = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
    CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData,
                                                    iplimage->width,
                                                    iplimage->height,
                                                    iplimage->depth,
                                                    iplimage->widthStep,
                                                    colorSpace,
                                                    kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2RGB);
    cvReleaseImage(&iplimage);
    
    return ret;
}

- (UIImage*) CreateUIImageFromIplImage:(IplImage*)image
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width,
                                        image->height,
                                        image->depth,
                                        image->depth * image->nChannels,
                                        image->widthStep,
                                        colorSpace,
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}

struct Node
{
    int x;
    int y;
    Node* next;
};

IplImage* RegionGrow(IplImage* src, int seedx, int seedy, int threshold, bool flag)
{
    if(!src || src->nChannels != 1)return src;
    
    int width = src->width;
    int height = src->height;
    int srcwidthstep = src->widthStep;
    uchar* img = (uchar*)src->imageData;
    
    IplImage *dst = cvCreateImage(cvGetSize(src), 8, 1);
    cvZero(dst);
    
    // flag
    IplImage* M = cvCreateImage(cvSize(width, height), 8, 1);
    int Mwidthstep = M->widthStep;
    
    cvZero(M);
    M->imageData[seedy * Mwidthstep + seedx] = 1;    // seed:1, others:0
    
    CvScalar cur = CV_RGB(255, 255, 255);
    cvSet2D(dst, seedy, seedx, cur);
    
    int start = 0;
    int end = 1;
    
    Node *queue = new Node;
    queue->x = seedx;
    queue->y = seedy;
    queue->next = NULL;
    Node *first = queue;
    Node *last = queue;
    
    while (end - start > 0)
    {
        int x = first->x;
        int y = first->y;
        uchar pixel = (uchar)img[y * srcwidthstep + x];
        
        for (int yy = -1; yy<=1; yy++)
        {
            for (int xx = -1; xx<=1; xx++)
            {
                if(flag)
                    if ( abs(yy) && abs(xx))
                        continue;
                
                int cx = x + xx;
                int cy = y + yy;
                if (cx >= 0 && cx <width && cy >=0 && cy < height)
                {
                    if (abs(img[cy * srcwidthstep + cx] - pixel) <= threshold &&
                        M->imageData[cy * Mwidthstep + cx] != 1)
                    {
                        Node *node = new Node;
                        node->x = cx;
                        node->y = cy;
                        node->next = NULL;
                        
                        end++;
                        last->next = node;
                        last = node;
                        
                        M->imageData[cy * Mwidthstep + cx] = 1;
                        
                        cvSet2D(dst, cy, cx, cur);
                    }
                }
            }
        }
        Node* temp = first;
        first = first->next;
        delete temp;
        start++;
    }
    
    cvReleaseImage(&M);
    cvReleaseImage(&src);
    
    return dst;
}

-(UIImage *)xorColorWithOpenCV:(UIImage* )image
{
    IplImage* src = [self CreateIplImageFromUIImage:image];
    
    cvNot(src, src);
    
    return [self CreateUIImageFromIplImage:src];
}

-(UIImage *)RegionGrowWithOpenCV:(UIImage* )image withCGPoint:(CGPoint)point
{
    IplImage* src = [self CreateIplImageFromUIImage:image];
    
    return [self CreateUIImageFromIplImage:RegionGrow(src, point.x, point.y, 0, false)];
}


// get bin index for each image pixel, store it in binPerPixelImg
void getBinPerPixel(cv::Mat & binPerPixelImg, cv::Mat & inputImg, int numBinsPerChannel, int & numUsedBins)
{
    // this vector is used to through away bins that were not used
    cv::vector<int> occupiedBinNewIdx((int)pow((double)numBinsPerChannel,(double)3),-1);

    // go over the image
    int newBinIdx = 0;
    for(int i=0; i<inputImg.rows; i++)
    {
        for(int j=0; j<inputImg.cols; j++)
        {
            // You can now access the pixel value with cv::Vec3b
            float b = (float)inputImg.at<cv::Vec3b>(i,j)[0];
            float g = (float)inputImg.at<cv::Vec3b>(i,j)[1];
            float r = (float)inputImg.at<cv::Vec3b>(i,j)[2];
            
            // this is the bin assuming all bins are present
            int bin = (int)(floor(b/256.0 *(float)numBinsPerChannel) + (float)numBinsPerChannel * floor(g/256.0*(float)numBinsPerChannel)
                            + (float)numBinsPerChannel * (float)numBinsPerChannel * floor(r/256.0*(float)numBinsPerChannel));
            
            
            // if we haven't seen this bin yet
            if (occupiedBinNewIdx[bin]==-1)
            {
                // mark it seen and assign it a new index
                occupiedBinNewIdx[bin] = newBinIdx;
                newBinIdx ++;
            }
            // if we saw this bin already, it has the new index
            binPerPixelImg.at<float>(i,j) = (float)occupiedBinNewIdx[bin];
        }
    }
    double maxBin;
    minMaxLoc(binPerPixelImg,NULL,&maxBin);
    numUsedBins = (int) maxBin + 1;
    
    occupiedBinNewIdx.clear();
}

// compute the variance of image edges between neighbors
void getEdgeVariance(cv::Mat& inputImg, cv::Mat& showEdgesImg, float& varianceSquared)
{
    varianceSquared = 0;
    int counter = 0;
    for(int i=0; i<inputImg.rows; i++)
    {
        for(int j=0; j<inputImg.cols; j++)
        {
            // You can now access the pixel value with cv::Vec3b
            float b = (float)inputImg.at<cv::Vec3b>(i,j)[0];
            float g = (float)inputImg.at<cv::Vec3b>(i,j)[1];
            float r = (float)inputImg.at<cv::Vec3b>(i,j)[2];
            for (int si = -1; si <= 1 && si + i < inputImg.rows && si + i >= 0 ; si++)
            {
                for (int sj = 0; sj <= 1 && sj + j < inputImg.cols ; sj++)
                    
                {
                    if ((si == 0 && sj == 0) ||
                        (si == 1 && sj == 0) ||
                        (si == 1 && sj == 0))
                        continue;
                    
                    float nb = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[0];
                    float ng = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[1];
                    float nr = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[2];
                    
                    varianceSquared+= (b-nb)*(b-nb) + (g-ng)*(g-ng) + (r-nr)*(r-nr);
                    counter ++;
                }
            }
        }
    }
    varianceSquared/=counter;
    
    // just for visualization
    for(int i=0; i<inputImg.rows; i++)
    {
        for(int j=0; j<inputImg.cols; j++)
        {
            float edgeStrength = 0;
            // You can now access the pixel value with cv::Vec3b
            float b = (float)inputImg.at<cv::Vec3b>(i,j)[0];
            float g = (float)inputImg.at<cv::Vec3b>(i,j)[1];
            float r = (float)inputImg.at<cv::Vec3b>(i,j)[2];
            for (int si = -1; si <= 1 && si + i < inputImg.rows && si + i >= 0; si++)
            {
                for (int sj = 0; sj <= 1 && sj + j < inputImg.cols   ; sj++)
                {
                    if ((si == 0 && sj == 0) ||
                        (si == 1 && sj == 0) ||
                        (si == 1 && sj == 0))
                        continue;
                    
                    float nb = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[0];
                    float ng = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[1];
                    float nr = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[2];
                    
                    //   ||I_p - I_q||^2  /   2 * sigma^2
                    float currEdgeStrength = exp(-((b-nb)*(b-nb) + (g-ng)*(g-ng) + (r-nr)*(r-nr))/(2*varianceSquared));
                    float currDist = sqrt((float)si*(float)si + (float)sj * (float)sj);
                    
                    // this is the edge between the current two pixels (i,j) and (i+si, j+sj)
                    edgeStrength = edgeStrength + ((float)0.95 * currEdgeStrength + (float)0.05) /currDist;
                }
            }
            // this is the avg edge strength for pixel (i,j) with its neighbors
            showEdgesImg.at<float>(i,j) = edgeStrength;
        }
    }
}

// init all images/vars
int setupImages()
{
    // Check for invalid input
    if(!inputImg.data)
    {
        return -1;
    }
    
    // this is the mask to keep the user scribbles
    fgScribbleMask.create(2, inputImg.size, CV_8UC1);
    //cvZero(&fgScribbleMask);
    bgScribbleMask.create(2, inputImg.size, CV_8UC1);
    //cvZero(&bgScribbleMask);
    segMask.create(2, inputImg.size, CV_8UC1);
    //cvZero(&segMask);
    showEdgesImg.create(2, inputImg.size, CV_32FC1);
    //cvZero(&showEdgesImg);
    binPerPixelImg.create(2, inputImg.size,CV_32F);

    // get bin index for each image pixel, store it in binPerPixelImg
    getBinPerPixel(binPerPixelImg, inputImg, numBinsPerChannel, numUsedBins);
    
    // compute the variance of image edges between neighbors
    getEdgeVariance(inputImg, showEdgesImg, varianceSquared);
    
    myGraph = new GraphType(/*estimated # of nodes*/ inputImg.rows * inputImg.cols + numUsedBins,
                            /*estimated # of edges=11 spatial neighbors and one link to auxiliary*/ 12 * inputImg.rows * inputImg.cols);
    myGraph->add_node((int)inputImg.cols * inputImg.rows + numUsedBins);
    
    for(int i=0; i<inputImg.rows; i++)
    {
        for(int j=0; j<inputImg.cols; j++)
        {
            // this is the node id for the current pixel
            GraphType::node_id currNodeId = i * inputImg.cols + j;
            
            // add hard constraints based on scribbles
            if (fgScribbleMask.at<uchar>(i,j) == 255)
                myGraph->add_tweights(currNodeId,(int)ceil(INT32_CONST * HARD_CONSTRAINT_CONST + 0.5),0);
            else if (bgScribbleMask.at<uchar>(i,j) == 255)
                myGraph->add_tweights(currNodeId,0,(int)ceil(INT32_CONST * HARD_CONSTRAINT_CONST + 0.5));
            
            // You can now access the pixel value with cv::Vec3b
            float b = (float)inputImg.at<cv::Vec3b>(i,j)[0];
            float g = (float)inputImg.at<cv::Vec3b>(i,j)[1];
            float r = (float)inputImg.at<cv::Vec3b>(i,j)[2];
            
            // go over the neighbors
            for (int si = -1; si <= 1 && si + i < inputImg.rows && si + i >= 0 ; si++)
            {
                for (int sj = 0; sj <= 1 && sj + j < inputImg.cols; sj++)
                {
                    if ((si == 0 && sj == 0) ||
                        (si == 1 && sj == 0) ||
                        (si == 1 && sj == 0))
                        continue;
                    
                    // this is the node id for the neighbor
                    GraphType::node_id nNodeId = (i+si) * inputImg.cols + (j + sj);
                    
                    float nb = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[0];
                    float ng = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[1];
                    float nr = (float)inputImg.at<cv::Vec3b>(i+si,j+sj)[2];
                    
                    //   ||I_p - I_q||^2  /   2 * sigma^2
                    float currEdgeStrength = exp(-((b-nb)*(b-nb) + (g-ng)*(g-ng) + (r-nr)*(r-nr))/(2*varianceSquared));
                    float currDist = sqrt((float)si*(float)si + (float)sj*(float)sj);
                    
                    // this is the edge between the current two pixels (i,j) and (i+si, j+sj)
                    currEdgeStrength = ((float)0.95 * currEdgeStrength + (float)0.05) /currDist;
                    myGraph -> add_edge(currNodeId, nNodeId,    /* capacities */ (int) ceil(INT32_CONST*currEdgeStrength + 0.5), (int)ceil(INT32_CONST*currEdgeStrength + 0.5));
                }
            }
            // add the adge to the auxiliary node
            int currBin =  (int)binPerPixelImg.at<float>(i, j);
            
            myGraph -> add_edge(currNodeId, (GraphType::node_id)(currBin + inputImg.rows * inputImg.cols),
                                /* capacities */ (int) ceil(INT32_CONST*bha_slope+ 0.5), (int)ceil(INT32_CONST*bha_slope + 0.5));
        }
    }

    return 0;
}

-(CGRect)frameForImage:(UIImage*)image inImageViewAspectFit:(UIImageView*)imageView
{
    float imageRatio = image.size.width / image.size.height;
    float viewRatio = imageView.frame.size.width / imageView.frame.size.height;
    
    if(imageRatio < viewRatio)
    {
        float scale = imageView.frame.size.height / image.size.height;
        float width = scale * image.size.width;
        float topLeftX = (imageView.frame.size.width - width) * 0.5;
        return CGRectMake(topLeftX, 0, width, imageView.frame.size.height);
    }
    else
    {
        float scale = imageView.frame.size.width / image.size.width;
        float height = scale * image.size.height;
        float topLeftY = (imageView.frame.size.height - height) * 0.5;
        return CGRectMake(0, topLeftY, imageView.frame.size.width, height);
    }
}

- (void)drawLineLazySnapping:(CGPoint)locationPoint{
    if (self.image != nil) {
        
        CGRect imageFrame = [self frameForImage:self.image inImageViewAspectFit:self];
        
        CvPoint pt = cv::Point2f(locationPoint.x - imageFrame.origin.x, locationPoint.y - imageFrame.origin.y);
        if(prev_pt.x < 0)
            prev_pt = pt;

        cvLine(img, prev_pt, pt, paintColor[currentMode], 10, 8, 0);
        if (currentMode == 0) {
            line(fgScribbleMask, prev_pt, pt, 255, 10, 8, 0);
            //circle(fgScribbleMask,pt,scribbleRadius, 255,-1);
        }else{
            line(bgScribbleMask, prev_pt, pt, 255, 10, 8, 0);
            //circle(bgScribbleMask,pt,scribbleRadius, 255,-1);
        }
        prev_pt = pt;
        self.image = [self CreateUIImageFromIplImage:img];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint locationPoint = [[touches anyObject] locationInView:self];
    CGRect imageFrame = [self frameForImage:self.image inImageViewAspectFit:self];
    prev_pt = cv::Point2f(locationPoint.x - imageFrame.origin.x,locationPoint.y - imageFrame.origin.y);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint locationPoint = [[touches anyObject] locationInView:self];
    [self drawLineLazySnapping:locationPoint];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    prev_pt = cv::Point2f(-1, -1);
}

- (UIImage*)maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    
    CGImageRef maskRef = maskImage.CGImage;
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    return [UIImage imageWithCGImage:masked];
}

@end

