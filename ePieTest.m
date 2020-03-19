%% parameters

r = 40; %% radius of aperture
apshift = 10; %% half distance between the aperture positions
n = 30; %% number of pie loops
alpha = 0.0001;
beta = 1;
phiobjoffset= 0*pi;
dfpatterfignon = 1;

%% load image data
%% fluoresence image of cell, e.g. from www.invitrogen.com
%% or http://rsb.info.nih.gov/ij/images/FluorescentCells.jpg

%% Image resized to 201x201 pixel

fluo_cell = imread('cell2.jpg');
%fluo_cell = cell2_01;
fluo_cell_hsv = rgb2hsv(fluo_cell);
datamp = squeeze(fluo_cell_hsv(:,:,3));
datphase = 2*pi.*squeeze(fluo_cell_hsv(:,:,1))-pi;
dat = flipud(datamp.*exp(sqrt(-1)*datphase));

%% define the 4 positions
[x,y] = meshgrid(1:201,1:201);
xp(1) = 100-apshift; xp(2) = 100-apshift;
xp(3) = 100+apshift; xp(4) = 100+apshift;
yp(1) = 100-apshift; yp(2) = 100+apshift;
yp(3) = 100+apshift; yp(4) = 100-apshift;

%% model illumination functions (pinhole)

for i = 1:4

    probe(:,:,i) = sign(real(sqrt(r.^2-(x-xp(i)).^2-(y-yp(i)).^2)));
end

%% create diffraction patterns
for i = 1:4
    
sim(:,:,i) = (fft2(squeeze(probe(:,:,i)).*dat));
dp_exp(:,:,i) = abs(sim(:,:,i));

end

%% plot original data - hsv representation

figure(1); clf;
dathsv = zeros(size(dat,1),size(dat,2),3);
dathsv(:,:,1) = (angle(dat)+pi)./(2*pi);
dathsv(:,:,2) = ones(size(dat,1),size(dat,2));
dathsv(:,:,3) = abs(dat);
imshow(hsv2rgb(dathsv));
title('original object [hsv]');

%% initial guess for object
object = complex(rand(201),rand(201));

%% PIE loop
for i = 1:n

fprintf(['PIE iteration ' num2str(i,'%03d') ', error: ']);

%% loop over the 4 positions
for pos=1:4

obj = probe(:,:,pos).*object;
objnew = ifft2(dp_exp(:,:,pos).*exp(sqrt(-1).*angle(fft2(obj))));
update_function= conj(probe(:,:,pos)).*abs(probe(:,:,pos))./...
(conj(probe(:,:,pos)).*probe(:,:,pos)+alpha);

object_new = object +update_function.*(objnew-obj);
object = object_new;

err(:,:,pos) = (dp_exp(:,:,pos).^2 - (abs(fft2(obj))).^2).^2./(201.^2);
fprintf([' ' num2str(sum(sum(err(:,:,pos))),'%0.2d')]);

%% plot retrieved object in hsv representation
figure(2);
objecthsv = zeros(size(object,1),size(dat,2),3);
objecthsv(:,:,1) = (angle(object.*exp(sqrt(-1).*1*pi))+pi)./(2*pi);
objecthsv(:,:,2) = ones(size(object,1),size(object,2));
objecthsv(:,:,3) = abs(object)- (0.5+0.5*sign(abs(object)-1)).*...
    (abs(object)-1);
imagesc(hsv2rgb(objecthsv)); drawnow;
title('retrieved object [hsv]');
end


%% calculate average error

avg_err(i) = sum(sum(mean(err,3)));
fprintf(['\n average error is: ' num2str(avg_err(i),'%0.2d') '\n'])
end


%% plot error

figure(3);
plot(log10(avg_err));
title('log10 of average reciprocal space error')
xlabel('PIE iterations')

