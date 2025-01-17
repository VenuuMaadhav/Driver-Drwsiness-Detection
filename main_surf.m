clc;
clear all;
close all;
warning('off','all');
% % Get The Input Image
[filename,pathname] = uigetfile('images\*.bmp');
img = imread([pathname,filename]);
figure,imshow(img);title('Input Image');
% %  Scaling
img = imresize(img,[512,512]);
%% RGB To HSV Color Conversion
[Hue,Sat,Value] = rgb2hsv(img);
figure,imshow(Hue)
title('Hue')
figure,imshow(Sat)
title('Sat')
% jj = rgb2ycbcr(img);figure,imshow(jj)
% % Gray Conversion
[r c o] = size(img);
if o == 3
    gray = im2double(rgb2gray(img));
else
    gray = im2double(img);
end
% figure,imshow(gray);title('Gray Image');

%%  Fuzzy Rules Based Segmentation

% % Define Fussy Interference System
sys = newfis('fis');
% %  Specify the Image  Hue and Sat Gradient
sys = addvar(sys,'input','Hue',[0 1]);
sys = addvar(sys,'input','Sat',[0 1]);
% % Apply Input MemberShip Specify the  Triangular and Trapizoidal Function
sys = addmf(sys,'input',1,'Red1','trimf',[-0.1 0 0.1]);
sys = addmf(sys,'input',1,'Red2','trimf',[0.95 1 1]);
sys = addmf(sys,'input',1,'Yellow','trimf',[0.1 0.15 0.2]);
sys = addmf(sys,'input',1,'Green','trimf',[0.43 0.5 0.57]);
sys = addmf(sys,'input',1,'Blue','trapmf',[0.45 [0.57,0.73] 0.78]);
sys = addmf(sys,'input',1,'Noise1','trimf',[0.2 0.3 0.43]);
sys = addmf(sys,'input',1,'Noise2','trapmf',[0.78 [0.82,0.92] 0.98]);
sys = addmf(sys,'input',2,'Red','trapmf',[0.35 0.4 1 1.5]);
sys = addmf(sys,'input',2,'Red','trapmf',[0.35 0.4 1 1.5]);
sys = addmf(sys,'input',2,'Yellow','trapmf',[0.65 0.88 1 1.5]);
sys = addmf(sys,'input',2,'Green','trapmf',[0.6 0.85 1 1.5]);
sys = addmf(sys,'input',2,'Blue','trapmf',[0.6 0.85 1 1.5]);
% % getfis(fis,'input',1)
% %   Specify the Output Segmentation Image 
sys = addvar(sys,'output','result',[0 1]);
% % Apply Output MemberShip Specify the  Triangular and Trapizoidal Function
sys = addmf(sys,'output',1,'Red','trimf',[0.9 0.95 1]);
sys = addmf(sys,'output',1,'Black','trimf',[0 0.015 0.15]);
sys = addmf(sys,'output',1,'Yellow','trimf',[0.78 0.85 0.9]);
sys = addmf(sys,'output',1,'Green','trimf',[0.65 0.7 0.78]);
sys = addmf(sys,'output',1,'Blue','trimf',[0.47 0.55 0.65]);
sys = addmf(sys,'output',1,'Black','trimf',[0 0.015 0.15]);
sys = addmf(sys,'output',1,'Black','trimf',[0 0.015 0.15]);
% plot the Input and Output Membership Function
figure,
subplot(2,2,1);
plotmf(sys,'input',1);
title('Hue');
subplot(2,2,2);
plotmf(sys,'input',2);
title('Sat');
subplot(2,2,[3 4]);
plotmf(sys,'output',1);
title('Iout');

% %  Specify FIS Rules
r1 = 'If ((Hue is Red1) and (Sat is Red) then (result is Red))';
r2 = 'If ((Hue is Red2) and (Sat is Red) then (result is Black))';
r3 = 'If ((Hue is Yellow) and (Sat is Yellow) then (result is Yellow))';
r4 = 'If ((Hue is Green) and (Sat is Green) then (result is Green))';
r5 = 'If ((Hue is Blue) and (Sat is Blue) then (result is Blue))';
r6 = 'If ((Hue is Noise1) then (Result is Black))';
r7 = 'If ((Hue is Noise2) then (Result is Black))';

rulelist = [1 1 1 1 1;   %Column 1 - Index of membership function for first input             
            2 2 2 1 1;   %Column 2 - Index of membership function for second input
            3 3 3 1 1;   %Column 3 - Index of membership function for output
            4 4 4 1 1;   %Column 4 - Rule weight
            5 5 5 1 1;   % Column 5 - Fuzzy operator (1 for AND, 2 for OR)
            6 0 6 1 1;
            7 0 7 1 1;];
sys = addrule(sys,rulelist);

% % a = readfis('sys.fis');
% showrule(sys)
% showfis(sys) 
% plotfis(sys)
% surfview(sys)
% % Evalute FIS
Ieval = zeros(size(gray));
for i = 1: size(gray,2)
     Ieval(i,:) = evalfis([(Hue(i,:));(Sat(i,:));]',sys);
end
figure,imshow(Ieval,[]);title('Fuzzy Segmentation Image');

%% FIltering using Morpological and Region Properties
;
% % Step 1: Gray level slicing

[m,n] = size(Ieval);
gry_slic = zeros(m,n);
for i = 1:m
    for j = 1:n
        % use the condition 
        if Ieval(i,j) >= 0.539
            gry_slic(i,j) = 1;
        else
            gry_slic(i,j) = 0;
        end
    end
end
figure,imshow(gry_slic);title('Gray Level Slice')

% % Step 2:  Morpological Operator

bw = imclearborder(gry_slic,8);
bw1 = bwareaopen(bw,200);
figure,imshow(bw1);
se = strel('square',3);
g = imdilate(bw1,se);
 figure,
imshow(g);title('Morpological Filled Image')
% % Step 3: Extraction Of ROI

rp = regionprops(g,'BoundingBox');
% hold on 
% imshow(img);
for i = 1: length(rp)
 rectangle('Position',rp(i).BoundingBox,'EdgeColor','r','LineWidth',2 );
 imc{i,1} = imcrop(img,[rp(i).BoundingBox]);
%  imwrite(imc{i,1},[num2str(i),'.jpg']);
% figure,imshow(imc{i,1});title('ROI Extraction Image')
end
% for i = 1: length(rp)
%   figure,imshow(imc{i,1});title('ROI Extraction Image')
% end
% 
% %% SURF Feature Extraction 
% % % 
for i = 1:length(imc)
imx = im2double(rgb2gray(imc{i,1}));
p1 = detectSURFFeatures(imx);
% % Extract the features.
[f1,vpts1] = extractFeatures(imx,p1);
f2{i,1} = mean(f1);
end
final_feature1 = cell2mat(f2);
%% % Classification using KNN MODIFICATION
% % load feature;
% % % feature = feature';
load final_feature.mat;
load nn.mat;
model = fitcknn(final_feature,label{1,:});
yfit = predict(model,final_feature1);
for i = 1:length(yfit)
% if (yfit(i)>= 1 && yfit(i) <= 4) 
%     figure,imshow(imc{i,1});title('ROI Extraction Image');
% end
if yfit(i) == 1
    msgbox('Negative Denoted');
    figure,imshow(imc{i,1});title('ROI Extraction Image');
elseif yfit(i) == 2
    msgbox('Positive Denoted');
    figure,imshow(imc{i,1});title('ROI Extraction Image');
elseif yfit(i) == 3
    msgbox('Warning');
    figure,imshow(imc{i,1});title('ROI Extraction Image');
elseif yfit(i) == 4
    msgbox('General Information');
    figure,imshow(imc{i,1});title('ROI Extraction Image');
end
end
% % % % Performance Evalution
load yfit12.mat;
actual = label{1,:};
predi = yfit1;
EVAL = Evaluate(actual,predi);
LastName = {'Accuracy';'Sensitivity';'Specificity';'Precision';'Recall';'F-Measure';'G-mean'};
KNN = {EVAL(1);EVAL(2);EVAL(3);EVAL(4);EVAL(5);EVAL(6);EVAL(7)};
T = table(KNN,...
    'RowNames',LastName);
disp(T)

