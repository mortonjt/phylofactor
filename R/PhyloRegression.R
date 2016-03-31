PhyloRegression <- function(Data,X,frmla,Grps,method,choice,cl,Pbasis=1,...){
  #Groups taxa by "Grps" and regresses independent variable X on Data according to formula.
  #Regression is done for a set of groups, "Grps", out of a total possible set of taxa, "set" (e.g. can perform regression on log-ratio (1,2) over (3,4) out of (1,2,3,4,5))
  #Data - data matrix - rows are otus and columns correspond to X.
  #X - independent variable
  #frmla - object of class "formula" indicating the regression of variable "Data" in terms of variable "X".
  #Grps - set of groups (must be list of 2-element lists containing taxa within 'set')
  #method - method for amalgamation of groups, either 'add' or 'multiply'. 
     #'add' looks at the log-ratio of relative abundances of the taxa in the two groups of Grps[]
     #'ILR' uses geometric means as centers of groups, and regression is performed on balances of groups according to the ILR method of Egozcue et al. (2003)
  #choice - method for choosing the dominant partition in tree, either 't' or 'var'. 
     #'t' will choose dominant partition based on the Grps whose regression maximized the test-statistic
     #'var' will choose based on Grps which maximized the percent explained variance in the clr-transformed dataset.
  #cl - optional phyloCluster input for parallelization of regression across multiple groups.
  if(is.null(Pbasis)){Pbasis=1}
  n <- dim(Data)[1]
  
  ############# REGRESSION ################
  #these can both be parallelized 
  if (is.null(cl)){
    Y <- lapply(X=Grps,FUN=amalgamate,Data=Data,method)
    GLMs <- lapply(X=Y,FUN = phyloreg,x=X,frmla=frmla,choice,...)
  } else {
    ## the following includes paralellization of residual variance if choice=='var'
    dum <- phyloregPar(Grps,Data,X,frmla,choice,method,Pbasis,cl,...)
    GLMs <- dum$GLMs
    Y <- dum$Y
  }
  stats <- matrix(unlist(lapply(GLMs,FUN=getStats)),ncol=2,byrow=T) #contains Pvalues and F statistics
  colnames(stats) <- c('Pval','F')
  Yhat <- lapply(GLMs,predict)
  
  ############# CHOICE - EXTRACT "BEST" CLADE ##################
  if (choice=='F'){
    #in this case, the GLM outputs was an F-statistic.
    clade <- which(stats[,'F']==max(stats[,'F']))
  } else { #we pick the clade that best reduces the residual variance. Since all have the same total variance
           #this means we pick the clade with the minimum residual variance.
           #To be clear, here for total variance of a data matrix, X, I'm using var(c(X)).
    
      #the  GLM.outputs above are predictions on log-ratios based on the "amalgamation" function.
      #The computation of percent variance explained by each 
      #partition can also be parallelized. A function such as 
      #phyloregPar and phyloregParV will be useful to parellelize
      # Y, GLM.outputs, and PercVar
      totalvar <- var(c(clr(t(Data))))
      if (is.null(cl)){
        predictions <- mapply(PredictAmalgam,Yhat,Grps,n,method,Pbasis,SIMPLIFY=F)
        residualvar <- sapply(predictions,residualVar,Data=Data)
        clade <- which(residualvar == min(residualvar))
      } else {
        clade <- which(dum$residualvar==min(dum$residualvar))
      }
    if (length(clade)>1){stop('minimizing residual variance produced  more than one group')}
  }
  node <- names(clade)
  
  ############ OUTPUT ##########################
  output <- NULL
  output$group <- clade #this is helps us pull out the Group from getGroups(tree)
  output$node <- as.numeric(node) #this helps us plot the group, nodelabels(text = 'here',node=node)
  if (method=='ILR'){
    output$basis <- ilrvec(Grps[[clade]],n) #this allows us to quickly project other data onto our partition
  } else { ### need too build basis for method='add'
    output$basis <- .............
  }
  output$glm <-GLMs[clade]         #this will enable us to easily extract effects and contrasts between clades, as well as project beyond our dataset for quantitative independent variables.
  output$p.values <- stats[,'Pval']   #this can allow us to do a KS test on P-values as a stopping function for PhyloFactor
  if (choice=='var'){
    if (is.null(cl)){
      output$explainedvar <- residualvar[clade]/totalvar
    } else {
      output$explainedvar <- dum$residualvar[clade]/totalvar
    }
  }
  output$residualData <- PredictAmalgam(Yhat[[clade]],Grps[[clade]],n,method,Pbasis)
  
  return(output)
}