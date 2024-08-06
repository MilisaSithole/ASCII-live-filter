import processing.video.*;

String density = " .:-=+*#%@$&XBWM";
int denLen = density.length();
float pxSize = 8;
Capture cam;
PFont monoFont;
// color bg = color(12, 12, 51);
color bg = color(0);
color txtCol = color(205, 205, 255);
boolean monoChrome = false;
boolean doEdges = true;

float[][] sobelX = {{0.5, 0, -0.5}, 
                    {1, 0, -1}, 
                    {0.5, 0, -0.5}};
float[][] sobelY = {{0.5, 1, 0.5}, 
                    {0, 0, 0}, 
                    {-0.5, -1, -0.5}};

void setup() {
    // size(1080, 1080);
    fullScreen();
    background(bg);

    monoFont = createFont("Monaco", pxSize);
    cam = new Capture(this, int(width / pxSize), int(height / pxSize));
    cam.start();
}  

void draw() {
    background(bg);

    if(cam.available()){
        cam.read();
    }

    // Flip the feed
    pushMatrix();
    scale(-1, 1);
    translate(-width, 0);
    popMatrix();

    drawAscii(cam);
    if(doEdges)
        drawEdges(cam);

}

void keyPressed() {
    if(key == 's')
        save("example" + frameCount + ".png");
    if(key == 'm')
        monoChrome = !monoChrome;

    if(key == 'e'){
        doEdges = !doEdges;
    }
}

float getPxBrightness(color pxColor){
    return (red(pxColor) + green(pxColor) + blue(pxColor)) / 3;
}

float conv(int x, int y, float[][] kernel, PImage img){
    float sum = 0;

    for(int i = -1; i <= 1; i++){
        for(int j = -1; j <= 1; j++){
            int xPos = x + i;
            int yPos = y + j;

            if(xPos >= 0 && xPos < img.width && yPos >= 0 && yPos < img.height){
                float brightness = getPxBrightness(img.get(xPos, yPos));
                sum += brightness * kernel[i+1][j+1];
            }
        }
    }

    return sum;
}

void drawAscii(PImage img){
    for(int i = 0; i < img.width; i++){
        for(int j = 0; j < img.height; j++){
            // get the color of the pixel
            color pxCol = img.get(i, j);
            pxCol = color(floor(red(pxCol) / denLen) * denLen, floor(green(pxCol) / denLen) * denLen, floor(blue(pxCol) / denLen) * denLen);

            float aveCol = getPxBrightness(pxCol);
            int charIdx = floor((aveCol / 255) * density.length());
            if(charIdx >= density.length()) 
                charIdx = density.length() - 1;

            noStroke();
            fill(pxCol);
            if(monoChrome) fill(txtCol);

            textAlign(CENTER, CENTER);
            textSize(pxSize);
            text(density.charAt(charIdx), i * pxSize + (pxSize/2), j * pxSize + (pxSize/2));
       }
    }    
}

void drawBGSquares(PImage img){
    for(int i = 0; i < img.width; i++){
        for(int j = 0; j < img.height; j++){
            // get the color of the pixel
            color pxCol = img.get(i, j);
            pxCol = color(floor(red(pxCol) / denLen) * denLen, floor(green(pxCol) / denLen) * denLen, floor(blue(pxCol) / denLen) * denLen);

            float aveCol = getPxBrightness(pxCol);
            int charIdx = floor((aveCol / 255) * density.length());
            if(charIdx >= density.length()) 
                charIdx = density.length() - 1;

            noStroke();
            fill(pxCol);
            square(i * pxSize, j * pxSize, pxSize);
       }
    }    
}

PImage getSobelImage(PImage img){
    PImage sobelImage = createImage(img.width, img.height, RGB);
    sobelImage.loadPixels();

    for(int i = 0; i < img.width; i++){
        for(int j = 0; j < img.height; j++){
            float xConv = conv(i, j, sobelX, img);
            float yConv = conv(i, j, sobelY, img);
            float brightness = sqrt(xConv * xConv + yConv * yConv);

            sobelImage.pixels[i + j * img.width] = color(brightness);
        }
    }

    sobelImage.updatePixels();
    return sobelImage;
}

void drawEdges(PImage img){
    for(int i = 0; i < img.width; i++){
        for(int j = 0; j < img.height; j++){
            float Gy = conv(i, j, sobelY, img);
            float Gx = conv(i, j, sobelX, img);

            if(abs(Gy) + abs(Gx) < 100) continue;

            float theta = atan2(Gy, Gx);
            theta /= PI * 2;
            theta += 0.5;

            noStroke();
            fill(bg);
            square(i * pxSize, j * pxSize, pxSize);

            char edgeChar = ' ';
            if((theta >= 0 && theta < 0.05) || (theta >= 0.45 && theta < 0.55) || (theta >= 0.95 && theta <= 1)) edgeChar = '_';
            if((theta >= 0.05 && theta < 0.2) || (theta >= 0.55 && theta < 0.7)) edgeChar = '/';
            if((theta >= 0.2 && theta < 0.3) || (theta >= 0.7 && theta < 0.8)) edgeChar = '|';
            if((theta >= 0.3 && theta < 0.45) || (theta >= 0.8 && theta < 0.95)) edgeChar = '\\';


            color pxCol = img.get(i, j);
            pxCol = color(floor(red(pxCol) / denLen) * denLen, floor(green(pxCol) / denLen) * denLen, floor(blue(pxCol) / denLen) * denLen);
            fill(pxCol);
            if(monoChrome) fill(txtCol);
            textSize(pxSize);
            textAlign(CENTER, CENTER);
            text(edgeChar, i * pxSize + (pxSize/2), j * pxSize + (pxSize/2));
        }
    }
}

float[][] createGaussianKernel(float sigma){
    int size = round(6 * sigma);
    if(size % 2 == 0) 
        size++;
    float[][] kernel = new float[size][size];
    float sum = 0;

    for(int i = 0; i < size; i++){
        for(int j = 0; j < size; j++){
            int yOff = i - (size / 2);
            int xOff = j - (size / 2);
            kernel[i][j] = exp(-(xOff * xOff + yOff * yOff) / (2 * sigma * sigma));
            sum += kernel[i][j];
        }
    }

    for(int i = 0; i < size; i++)
        for(int j = 0; j < size; j++)
            kernel[i][j] /= sum;

    return kernel;
}

PImage getBlurredImage(PImage img, float sigma){
    float[][] blurKernel = createGaussianKernel(sigma);
    PImage blurredImage = createImage(img.width, img.height, RGB);
    blurredImage.loadPixels();

    for(int i = 0; i < img.width; i++){
        for(int j = 0; j < img.height; j++){
            float sum = 0, weightedSum = 0;

            for(int ki = -blurKernel.length/2; ki <= blurKernel.length/2; ki++){
                for(int kj = -blurKernel[0].length/2; kj <= blurKernel[0].length/2; kj++){
                    int xPos = i + ki;
                    int yPos = j + kj;
                    if(xPos >= 0 && xPos < img.width && yPos >= 0 && yPos < img.height){
                        float weight = blurKernel[ki + blurKernel.length/2][kj + blurKernel[0].length/2];
                        sum += getPxBrightness(img.get(xPos, yPos)) * weight;
                        weightedSum += weight;
                    }
                }
            }

            blurredImage.pixels[i + j * img.width] = color(sum / weightedSum);
        }
    }

    blurredImage.updatePixels();
    return blurredImage;
}

PImage getDoG(PImage img, float sigma1, float sigma2){
    PImage blurredImg1 = getBlurredImage(img, sigma1);
    PImage blurredImg2 = getBlurredImage(img, sigma2);
    PImage DoG = createImage(img.width, img.height, RGB);
    DoG.loadPixels();

    for(int i = 0; i < img.width; i++)
        for(int j = 0; j < img.height; j++)
            DoG.pixels[i + j * img.width] = color(abs(getPxBrightness(blurredImg1.get(i, j)) - getPxBrightness(blurredImg2.get(i, j))));

    DoG.updatePixels();
    return DoG;
}