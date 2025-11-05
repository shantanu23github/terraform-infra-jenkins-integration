data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ssm_parameter.ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.app_security_group_id]

  user_data = base64encode(templatefile("${path.module}/userdata.tpl", { }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${var.name}-instance" })
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name}-asg"
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.asg_min
  desired_capacity    = var.asg_desired
  max_size            = var.asg_max
  health_check_type   = "ELB"
  target_group_arns   = [var.tg_arn]

  tag {
    key                 = "Name"
    value               = "${var.name}-asg-instance"
    propagate_at_launch = true
  }
}
