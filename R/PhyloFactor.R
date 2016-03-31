PhyloFactor <- function(Data,tree,X,frmla = NULL,method='ILR',choice='var',nclades=NULL,stop.fcn=NULL,cl=NULL,...){
 #Data - Data Matrix, rows must be labelled as in tree and columns labelled by indepedent variable, X
 #tree - Phylogeny
 #X - independent variable
 #method - amalgamation method, either "add" or "ILR". ILR groups by multiplication, consistent with Egozcue's ILR basis
 #choice - how to choose the best edge, either "F" for F-statistic from analysis of variance of the glm, or "var" for percent explained variance.
 #cl - optional phyloCluster for parellelization of PhyloRegression.
  # note - future input "GPU" will enable GPU computing.
 #... arguments for glm(), such as family, weights, subset, etc.

  #### Housekeeping
  if (all(colnames(Data) != X)){stop('column names of Data do not correspond to X')}
  if (all(rownames(Data) %in% tree$tip.label)==F){stop('some rownames of Data are not found in tree')
     } else {if (all(rownames(Data)!=tree$tip.label)){ #we need to re-arrange the data matrix to correspond to the tree tip labels
       Data <- Data[match(rownames(Data),tree$tip.label),]
     }}
  if (is.null(frmla)){frmla=Data ~ X}
  if (method %in% c('add','ILR')==F){stop('improper input method - must be either "add" or "multiply"')}
  if (choice %in% c('F','var')==F){stop('improper input "choice" - must be either "t" or "var"')}
  if(is.null(nclades)){nclades=Inf}
  if(is.rooted(tree)){
    warning('Tree is rooted. Output nodes will correspond to unrooted, tree <- unroot(tree)')
    tree <- unroot(tree)}
  
  
 #### Get list of groups from tree ####
 Grps <- getGroups(tree)
 # This is a list of 2-element lists containing the partitioning of tips 
 # in our tree according to the edges. The groups can be mapped to the tree
 # via the node given names(Grps)[i]. The OTUs corresponding to the Groups can be found with:
 ### Get OTUs from tree
 OTUs <- tree$tip.label

 ################ OUTPUT ###################
 output <- NULL
 output$method <- method
 
 pfs=1
 while (pfs <= min(length(OTUs)-1,nclades)){
   
   if (pfs>1){
   Data <- t(clo(t(Data/PhyloReg$residualData)))
   Grps <- removeGroup(Grps,PhyloReg$group) #removeGroup can be made more efficient if need be.
   }
   
   ############# Perform Regression on all of Groups, and implement choice function ##############
   # PhyloReg <- PhyloRegression(Data=Data,X=X,frmla=frmla,Grps=Grps,method,choice)
   PhyloReg <- PhyloRegression(Data,X,frmla,Grps,method,choice,cl,...)
   
   
   ############# update output ########################
   # output$group <- c(output$group,PhyloReg$group)
   output$nodes <- c(output$nodes,PhyloReg$node)
   output$glms <- c(output$glms,PhyloReg$glm)
   if (choice=='var'){
     if (pfs==1){
       output$ExplainedVar <- PhyloReg$explainedvar
     } else {
      output$ExplainedVar <- c(output$ExplainedVar,output$ExplainedVar[pfs-1]*PhyloReg$explainedvar)
     }
   }
   output$basis <- output$basis %>% c(PhyloReg$basis) %>% matrix(ncol=pfs,byrow=F)
   
   
   ############# Decide whether or not to stop based on PhyloReg #################
   if (is.null(stop.fcn)==F){
     if (stop.fcn=='KS'){
       ks <- ks.test(PhyloReg$p.values,runif(length(PhyloReg$p.values)))$p.value
       if (ks>0.01){break}
     } else {
      stop.fcn(PhyloReg)
     }
   }
   
   
   ### If we haven't stopped, let's update the key variables
   pfs=pfs+1
 }
 
 output$atoms <- atoms(output$basis)
 return(output)
}

