//
//  WHH_LoopView.swift
//  WHHTravel
//
//  Created by dhhsMac on 2017/9/18.
//  Copyright © 2017年 dhhsMac. All rights reserved.
//

import UIKit
import Kingfisher

private let collectionViewCellID = "collectionViewCellID"
private let pageControlHeight = CGFloat(30.0)
private let maxCellCount = 4000000
private let intervalTime = 5

//点击图片的代理
@objc protocol loopViewDelegate: NSObjectProtocol {
    
    @objc optional func loopView(_ loopView: WHH_LoopView, didSelectItemAt index: Int, dataModel: WHH_LoopViewModel)
}

class WHH_LoopView: UIView {
    
    //当前图片的序号
    fileprivate var currenImageIndex: Int = 0
    //显示图片的View
    fileprivate var collectionView: UICollectionView?
    //分页
    fileprivate var pageControl: UIPageControl?
    //数据
    var imageData: [WHH_LoopViewModel]? {
        
        didSet {
            
            collectionView?.reloadData()
            pageControl?.numberOfPages = imageData?.count ?? 0
            
            DispatchQueue.main.async {
                guard let count = self.imageData?.count else {
                    return
                }
                
                let indexPath = NSIndexPath(item: count*maxCellCount/2, section: 0)
                self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: [], animated: false)
                self.currenImageIndex = indexPath.item
                
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //计时器
    fileprivate var timer: Timer?
    
    //是否自动轮播
    var isAutoLoop: Bool = true {
        
        didSet {
            if isAutoLoop {
                self.timer?.fireDate = Date.distantPast
            }else {
                self.timer?.fireDate = Date.distantFuture
            }
        }
    }
    
    //代理
    var delegate: loopViewDelegate?
    
}

extension WHH_LoopView {
    
    fileprivate func setupUI() {
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = bounds.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: collectionViewCellID)
        collectionView?.bounces = false;//禁止回弹
        collectionView?.isPagingEnabled = true;
        collectionView?.showsVerticalScrollIndicator = false;
        collectionView?.showsHorizontalScrollIndicator = false;
        
        addSubview(collectionView!)
        
        pageControl = UIPageControl(frame: CGRect(x: 0, y: bounds.size.height-pageControlHeight, width: bounds.size.width, height: pageControlHeight))
        pageControl?.currentPageIndicatorTintColor = UIColor.white
        pageControl?.pageIndicatorTintColor = UIColor.purple
        
        addSubview(pageControl!)
        
        //设置定时器
        if timer == nil && isAutoLoop {
            timer = Timer.scheduledTimer(timeInterval: TimeInterval(intervalTime), target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }
    }
    
    @objc fileprivate func timerAction() {
//        print("定时器\(intervalTime)秒钟")
        currenImageIndex += 1
        guard let allCellCount = collectionView?.numberOfItems(inSection: 0) else {
            return
        }
        if currenImageIndex == allCellCount {
            currenImageIndex = 0
        }
        let indexPath = NSIndexPath(item:currenImageIndex, section: 0)
        collectionView?.scrollToItem(at: indexPath as IndexPath, at: [], animated: true)
    }
}


// MARK: - UICollectionViewDelegate,UICollectionViewDataSource
extension WHH_LoopView: UICollectionViewDelegate,UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (imageData?.count ?? 0)*maxCellCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellID, for: indexPath)
        
        let imageView = UIImageView(frame: cell.contentView.bounds)
        
        let loopViewModel = imageData?[indexPath.item % (imageData?.count)!]
        
        imageView.kf.setImage(with: URL(string: loopViewModel?.imageUrl ?? ""))
        
        cell.contentView.addSubview(imageView)
        
        return cell
        
    }
    
    //点击代理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let index = indexPath.item % (imageData?.count)!
        let loopViewModel = imageData?[index]
        
        delegate?.loopView!(self, didSelectItemAt: index, dataModel: loopViewModel!)
    }
    
    //通过代码滑动  setContentOffset/scrollToItem
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        pageControl?.currentPage = currenImageIndex % (imageData?.count)!
    }
    
    //手动滑动
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if isAutoLoop {
            timer?.fireDate = Date.distantFuture
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        //没有减速动画
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
        
        if isAutoLoop {
            timer?.fireDate = Date(timeIntervalSinceNow: TimeInterval(intervalTime))
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
     
        var index = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
        guard let allCellCount = collectionView?.numberOfItems(inSection: 0) else {
            return
        }
        
        if index == 0 {
            
            index = allCellCount / 2
        }
        
        if index == allCellCount-1 {
            
            index = allCellCount / 2 - 1
        }
        
        collectionView?.contentOffset = CGPoint(x: CGFloat(index) * scrollView.bounds.size.width, y: 0)
        pageControl?.currentPage = index % (imageData?.count)!
        
        currenImageIndex = Int(index)
    }
}
