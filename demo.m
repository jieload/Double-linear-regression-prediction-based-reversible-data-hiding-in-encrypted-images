%% data
clear;
clc;
warning('off');
threshold=10;   
bitplane=3;   
payload=1;
im=imread('TestImage\lena.bmp');  
imorg = imresize(im,[512,512]);
imorg = uint8(imorg);
figure('name','original image');imshow(imorg);
im = double(imorg);
[m, n] = size(im);
mess_len = ceil(m*n*payload); 
message = mod(ceil(rand(mess_len,1)*10000),2); 
message = int8(message);
message = imresize(message,[512 512]);

x1=zeros(1,(m-1)*(n-1));   
x2=zeros(1,(m-1)*(n-1));
x3=zeros(1,(m-1)*(n-1));
x4=zeros(1,(m-1)*(n-1));
y=zeros(1,(m-1)*(n-1));
s=zeros(1,(m-1)*(n-1));
precount=0;
count=0;
for i=2:m
    for j=2:n
        count=count+1;
        if j==512
            tem_x4=im(i-1,j);
        else
            tem_x4=im(i-1, j+1);
        end
        s=abs(im(i, j)-im(i-1, j-1))+abs(im(i, j)-im(i-1, j))+abs(im(i, j)-im(i, j-1))+abs(im(i,j)-tem_x4);
        if s<=threshold
            x1(1,count)=im(i-1, j-1);
            x2(1,count)=im(i-1, j);
            x3(1,count)=im(i, j-1);
            if j==512
                x4(1,count)=im(i-1,j);
            else
                x4(1,count)=im(i-1, j+1);
            end
            y(1,count)=im(i, j);
        end
    end
end

%% double-linear
X1 = [ones(length(y),1), x1', x2', x3'];
Y1 = y';
[b1, bint1, r1, rint1, stats1]=regress(Y1,X1);
b1; bint1; stats1; 
Yhat1 = X1*b1;  

X2 = [ones(length(y),1), x1', x3', x4'];
Y2 = y';
[b2, bint2, r2, rint2, stats2]=regress(Y2,X2);
b2; bint2; stats2;
Yhat2 = X2*b2;

X3 = [ones(length(y),1), x2', x3', x4'];
Y3 = y';
[b3, bint3, r3, rint3, stats3]=regress(Y3,X3);
b3; bint3; stats3;
Yhat3 = X3*b3;

X = [ones(length(y),1), Yhat1, Yhat2, Yhat3];
Y = y';
[b, bint, r, rint, stats]=regress(Y,X);
b; bint; stats; 
Yhat = X*b; 
Yhat=ceil(Yhat);

%% location
pre_err_num=0;    
count=0;
map=zeros(511,511);
for i=2:m
    for j=2:n
        if j==512
            tem_x4=im(i-1,j);
        else
            tem_x4=im(i-1, j+1);
        end
        s=abs(im(i, j)-im(i-1, j-1))+abs(im(i, j)-im(i-1, j))+abs(im(i, j)-im(i, j-1))+abs(im(i,j)-tem_x4);
        if s<threshold
            count=count+1;
            pf=bitset(im(i,j),bitplane,~bitget(im(i,j),bitplane));
            pr=Yhat(count,1);
            if(abs(pr-im(i,j))<abs(pr-pf))
                map(i,j)=0;
            else
                map(i,j)=1;
                pre_err_num=pre_err_num+1;
            end 
        end
    end
end

I=map;
[m,n]=size(I);
p1=1;s=m*n;
for k=1:m
    for L=1:n
        f=0;
        for b=1:p1-1
            if(c(b,1)==I(k,L))f=1;break;end
        end
        if(f==0)c(p1,1)=I(k,L);p1=p1+1;end
    end
end
for g=1:p1-1
    p(g)=0;c(g,2)=0;
    for k=1:m
        for L=1:n
            if(c(g,1)==I(k,L))p(g)=p(g)+1;end
        end
    end
    p(g)=p(g)/s;
end
pn=0;po=1;
while(1)
    if(pn>=1.0)break;
    else
        [pm,p2]=min(p(1:p1-1));p(p2)=1.1;
        [pm2,p3]=min(p(1:p1-1));p(p3)=1.1;
        pn=pm+pm2;p(p1)=pn;
        tree(po,1)=p2;tree(po,2)=p3;
        po=po+1;p1=p1+1;
    end
end
for k=1:po-1
    tt=k;m1=1;
    if(or(tree(k,1)<g,tree(k,2)<g))
        if(tree(k,1)<g)
            c(tree(k,1),2)=c(tree(k,1),2)+m1;
            m2=1;
            while(tt<po-1)
                m1=m1*2;
                for L=tt:po-1
                    if(tree(L,1)==tt+g)
                        c(tree(k,1),2)=c(tree(k,1),2)+m1;
                        m2=m2+1;tt=L;break;
                    elseif(tree(L,2)==tt+g)
                        m2=m2+1;tt=L;break;
                    end
                end
            end
            c(tree(k,1),3)=m2;
        end
        tt=k;m1=1;
        if(tree(k,2)<g)
            m2=1;
            while(tt<po-1)
                m1=m1*2;
                for L=tt:po-1
                    if(tree(L,1)==tt+g)
                        c(tree(k,2),2)=c(tree(k,2),2)+m1;
                        m2=m2+1;tt=L;break;
                    elseif(tree(L,2)==tt+g)
                        m2=m2+1;tt=L;break;
                    end
                end
            end
            c(tree(k,2),3)=m2;
        end
    end
end
maplength=length(dec2bin(tree))+length(dec2bin(c));
%% encryption
[M,N]=size(im);
x=0.77;
u=3.98;
for i=1:1000
    x=u*x*(1-x);
end
A=zeros(1,M*N*8);
A(1)=x;
for i=1:M*N*8-1
A(i+1)=u*A(i)*(1-A(i));
end
B=uint8(A);
for i=1:M*N
    C(i)=B(i*8-7)*2^7+B(i*8-6)*2^6+...
        B(i*8-5)*2^5+B(i*8-4)*2^4+...
        B(i*8-3)*2^3+B(i*8-2)*2^2+...
        B(i*8-1)*2^1+B(i*8);
end
Fuck=reshape(C,M,N);
im=bitxor(uint8(im),Fuck);
im = reshape(im,512,512);
encry_im=mat2gray(im);
figure('name','encryption image');
imshow(encry_im);
%% embedding
mess_len = mess_len+pre_err_num+maplength+3;
count=0;
embednum=0; 
for i=2:m  
    for j=2:n
        count = count+1; 
        if count>mess_len 
            break;
        end
        if map(i,j)==0
            im(i,j)=bitset(im(i,j),bitplane,message(count));
            embednum=embednum+1;
        end
    end
end
marked_encry_im=mat2gray(im);
figure('name','encryption image with secret data');
imshow(marked_encry_im);
%% decryption
im=bitxor(uint8(im),Fuck);
im = reshape(im,512,512);
marked_decry_im=uint8(im);
figure('name','decryption image with secret data');
imshow(marked_decry_im);
%% psnr and ssim
disp([' psnr ', ' ssim ']);
disp(psnr(marked_decry_im,imorg)); %psnr
disp(ssim(marked_decry_im,imorg)); %ssim